#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Initialize global variables
# that will be reused throughout
# this script.
declare_variables() {
  readonly assets="$(pwd)/assets"
  readonly leader_file="$assets/leader"
  readonly manager_file="$assets/manager"
  readonly worker_file="$assets/worker"
  readonly temp_ips_file="$assets/temp_ips"

  # Create temporary files
  touch $temp_ips_file
  touch $manager_file
  touch $worker_file
  cat $IPS > $temp_ips_file
}

#-------------------------------------------------------------------------------

# Send all of the asset files
# to each node in the cluster
send_assets() {
  echo "Sending assets to each node"
  $UTIL scp_nodes $(pwd)/setup.sh $assets/
  echo "Succesfuly sent assets to each node"
}

#-------------------------------------------------------------------------------

# From the global ip list, select the
# the first ip address as the leader
# of the swarm.
select_leader() {
  echo "Selecting leader node"

  # Get first line from ip list then
  # remove it from the ip list
  head -1 $temp_ips_file > $leader_file
  sed -i -e 1d $temp_ips_file

  $UTIL print_as_list "Leader will be:" $(cat $leader_file)
  $UTIL warn_static_ip
}

#-------------------------------------------------------------------------------

# We will take half of the workers ip addresses
# and promote them to manager status. We do this
# to comply with docker's 'quorum' rules. That is,
# for n nodes, (n+1) / 2 of them should be managers.
# This provides pretty good fault tolerance.
# In the event that the leader goes down,
# we won't lose the entire swarm. Any node
# with manager status can be picked and promoted
# to leader status.
select_managers() {
  local num_ips=$( $UTIL num_lines $temp_ips_file )
  local num_managers=$(( ($num_ips+1) / 2 ))

  # Get first (N+1) / 2 lines from ip list then
  # remove them from the ip list
  echo "Selecting managers"
  head -n $num_managers $temp_ips_file > $manager_file
  sed -i -e 1,${num_managers}d $temp_ips_file

  $UTIL print_as_list "The following node(s) will be manager(s):" \
        $(cat $manager_file)

  $UTIL warn_static_ip
}

#-------------------------------------------------------------------------------

# From the globla ip list, select
# all ip address except for the first
# to be a worker. NOTE - If we want
# managers, the workers file will be modified
# such that the first half of these adddresses
# get moved to the manager_file.
select_workers() {
  echo "Selecting workers"

  cat $temp_ips_file > $worker_file
  $UTIL print_as_list "The following node(s) will be worker(s):" \
        $(cat $worker_file)
}

#-------------------------------------------------------------------------------

# Download the join-token
# scripts from the leader node
download_tokens() {
  local leader_ip=$(cat $leader_file)

  echo "Downloading join-token scripts from leader: $leader_ip"
  $UTIL my_scp_get $leader_ip $(pwd)/assets/ manager_join_token.sh worker_join_token.sh
  echo "Successfully downloaed join-token scripts from leader"
}

#-------------------------------------------------------------------------------

# For all nodes in the global
# ip list, remove them from
# a swarm if they are part of
# an existing swarm.
disband_swarm() {
  echo "Removing all nodes from existing swarm"
  $UTIL ssh_nodes ./setup.sh leave_swarm
  echo "Successfully removed all nodes from existing swarm"
}

#-------------------------------------------------------------------------------

# SSH into the node that we selected
# as leader, initialize a new swarm,
# and generate join-token scripts that
# can be run on workers and managers
# so that they can join the new swarm.
init_swarm() {
  local leader_ip=$(cat $leader_file)

  echo "Initializing new swarm on: $leader_ip"
  $UTIL ssh_specific_nodes $leader_file ./setup.sh init_swarm
  echo "Successfully initialized new swarm"
}

#-------------------------------------------------------------------------------

# Adds either a list of workers
# or a list of managers to swarm.
join_swarm() {
  local node_type=$1; shift
  local node_file=$1
  local num_nodes=$( $UTIL num_lines $node_file )

  echo "Adding ${node_type}(s) to swarm"

  if [[ $num_nodes > 0 ]]; then

    echo "Sending and running $node_type join-token scipt on all ${node_type}(s)"
    $UTIL scp_ssh_specific_nodes $node_file \
          $(pwd)/assets/${node_type}_join_token.sh \
          ./${node_type}_join_token.sh

  else
    echo "No ${node_type}(s) to add to swarm"
  fi
}

#-------------------------------------------------------------------------------

# Loop through all manager ips and
# worker ips, send them the appropriate
# join script, and execute it to finilize
# the swarm creation process.
assemble_swarm() {
  echo "Assembling nodes to swarm"
  join_swarm "worker" $worker_file
  join_swarm "manager" $manager_file
  echo "Succesfully assembled swarm"
}

#-------------------------------------------------------------------------------

# Matches the first argument
# to a function in setup.sh
# with the naming convertion
# start_SERVICE_NAME. If the
# function is not present, we
# simply error out.
start_service() {
  local service=$1

  echo "Starting docker service: $service"
  $UTIL ssh_specific_nodes $leader_file ./setup.sh start_$service $COMMON_USER $COMMON_PASS
  echo "Successfully started docker service: $service"
}

#-------------------------------------------------------------------------------

# Executes all of the steps
# that are required to start up
# a new docker swarm.
install_swarm() {
  local services="$@"

  echo "Creating docker swarm"
  select_leader
  select_managers
  select_workers
  disband_swarm
  init_swarm
  download_tokens
  assemble_swarm
  start_service portainer
  echo "Successfully created docker swarm"
}

#-------------------------------------------------------------------------------

# Kick off the script.
main() {
  declare_variables
  send_assets
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

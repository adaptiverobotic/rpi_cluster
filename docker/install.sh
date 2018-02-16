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

# Installs latest version of
# docker on all nodes.
install_docker() {
  echo "Installing docker on each node"
  $UTIL ssh_nodes ./setup.sh reinstall_docker
  echo "Successfully installed docker on each node"
}

#-------------------------------------------------------------------------------

# From the global ip list, select the
# the first ip address as the leader
# of the swarm.
select_leader() {
  echo "Selecting leader node"

  # Write leader ip out to a file
  echo $(head -n 1 $IPS) > $leader_file

  # Make sure that there is exactly only 1 leader
  # ip specified in the leader file
  local lines=$($UTIL num_lines $leader_file)

  if [[ $lines -ne 1 ]]; then
    echo "There can only be exactly 1 leader"
    return 1
  fi

  echo ""
  echo "Leader will be:"
  echo "---------------"
  echo "$(cat $leader_file)"
  echo "---------------"
  echo ""
  echo "Make sure that it's ip address does not change"
  echo "Either assign it a static ip or reserve it's dhcp lease"
  echo ""
}

#-------------------------------------------------------------------------------

# From the globla ip list, select
# all ip address except for the first
# to be a worker. NOTE - If we want
# managers, the workers file will be modified
# such that the first half of these adddresses
# get moved to the manager_file.
select_workers() {
  echo "Generating list of worker node ips"

  # Grab all ips except the first, replace spaces with new lines
  echo $(tail -n +2 $IPS) | tr " " "\n" > $worker_file
  echo ""
  echo "The following is a list of all non-leader node(s)"
  echo "NOTE: Half of these node(s) will be promoted to manager(s) to meet docker swarm quorum"
  echo "The rest will maintain at worker status:"
  echo "----------------------------------------"
  echo $(cat $worker_file) | tr " " "\n"
  echo "----------------------------------------"
  echo ""
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
  local num_workers=$( $UTIL num_lines $worker_file )
  local num_managers=$(( $num_workers / 2 ))

  echo "Generating list of manager nodes"

  # (n+1) / 2 = quorum
  echo "There are $num_workers worker(s)"
  echo "Promoting $num_managers worker(s) to manager(s)"

  # Write their ips out to file
  echo $(head -$num_managers $worker_file) > $manager_file

  # If there are nodes to read in
  if [[ $num_managers > 0 ]]; then
    # Loop through each manager
    # and remove it from worker_file
    echo "The following nodes will be manager(s):"
    while read manager_ip; do

      echo $manager_ip

      # Remove it from the worker_file
      sed -i "/$manager_ip/d" $worker_file
    done <$manager_file
  fi

  # At this point, leader, managers, and workers
  # should all have unique ips. Together they represent
  # the ips in the $IPS file. However, when operating
  # on nodes by status, we must operate on all three files.
  # But, we can also do leader only, or worker only operations.
  echo "The following nodes will be worker(s):"
  cat $worker_file
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

# Simply install docker
# daemon on all nodes
docker_daemon() {
  echo "Installing docker daemon on each node"
  send_assets
  install_docker
  echo "Successfully installed docker daemon on each node"
}

#-------------------------------------------------------------------------------

start_service() {
  local service=$1

  echo "Starting docker service: $service"
  $UTIL ssh_specific_nodes $leader_file ./setup.sh start_$service $COMMON_USER $COMMON_PASS
  echo "Successfully started docker service: $service"
}

#-------------------------------------------------------------------------------

# Start all desired services
# that were passed as command
# line arguments
# TODO - Change name of this function
# if someone passes a service in named
# 'service', we will spiral into an infinite loop
start_services() {
  local services="$@"

  # TODO - Print on new line as tabbed list
  echo "Starting docker services: $services"
  for service in $services; do
    start_service $service
  done
  echo "Succesfully started docker services: $services"
}

#-------------------------------------------------------------------------------

# Executes all of the steps
# that are required to start up
# a new docker swarm.
swarm() {
  local services="$@"

  echo "Creating docker swarm"

  # TODO - Rename that function, wtf
  docker_daemon
  select_leader
  select_workers
  select_managers
  disband_swarm
  init_swarm
  download_tokens
  assemble_swarm
  start_services "$services"
  echo "Successfully created docker swarm"
}

#-------------------------------------------------------------------------------

# Kick off the script.
main() {
  declare_variables
  $UTIL clean_workspace $IPS
  "$@"
  $UTIL clean_workspace $IPS
}

#-------------------------------------------------------------------------------

main "$@"

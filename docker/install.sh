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

  # Capture leader_ip
  local leader_ip=$(cat $leader_file)
  echo "Leader will be: $leader_ip"
  echo "Make sure that it's ip address does not change"
  echo "Either assign it a static ip or reserve it's dhcp lease"
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
  echo $(tail -n +2 $IPS) | tr " " "\n" > $worker_file

  echo "The following is a list of all non-leader node(s)"
  echo "NOTE: Half of these node(s) will be promoted to manager(s) to meet docker swarm quorum"
  echo $(cat $worker_file)
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

# Loop through all manager ips and
# worker ips, send them the appropriate
# join script, and execute it to finilize
# the swarm creation process.
join_swarm() {
  echo "Assembling nodes to swarm"

  # Count number of workers and managers
  local num_managers=$( $UTIL num_lines $manager_file)
  local num_workers=$( $UTIL num_lines $worker_file)

  # TODO - duplicate code, abstract to function

  # If there is at least one worker
  # to add to the swarm
  if [[ $num_workers > 0 ]]; then

    # Send join-tokens to all nodes
    echo "Sending worker join-token script to workers"
    $UTIL scp_specific_nodes $worker_file $(pwd)/assets/worker_join_token.sh

    # Execute join-token script
    echo "Adding workers to swarm"
    $UTIL ssh_specific_nodes $worker_file ./worker_join_token.sh

  else
    echo "No workers to add to swarm"
  fi

  # If there is at least 1 manager
  # to deploy to
  if [[ $num_managers > 0 ]]; then

    # Send the join script
    echo "Sending manager join-token script to managers"
    $UTIL scp_specific_nodes $manager_file $(pwd)/assets/manager_join_token.sh

    # Execute it
    echo "Adding managers to swarm"
    $UTIL ssh_specific_nodes $manager_file ./manager_join_token.sh
  else
    echo "No managers to add to swarm"
  fi

  echo "Succesfully assembled swarm"
}

#-------------------------------------------------------------------------------

# Simply install docker
# daemon on all nodes
docker() {
  echo "Installing docker daemon"

  # Send setup files
  send_assets

  # Install docker
  install_docker

  echo "Successfully installed docker daemon"
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
  for service in $services;
  do
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

  # Install docker daemon
  docker

  # Pick a leader
  select_leader

  # Select the workers
  select_workers

  # Select the managers
  select_managers

  # Disband old swarms
  disband_swarm

  # Create new swarm
  init_swarm

  # Download join tokens
  download_tokens

  # Add nodes to swarm
  join_swarm

  # Start desired services
  start_services "$services"

  echo "Successfully created docker swarm"
}

#-------------------------------------------------------------------------------

# Kick off the script.
main() {

  # Initialize globals
  declare_variables

  # Clear home directory
  $UTIL clean_workspace $IPS

  # Execute whatever
  # command read in
  # from command line
  "$@"

  # Clear home directory
  # $UTIL clean_workspace $IPS
}

#-------------------------------------------------------------------------------

main "$@"

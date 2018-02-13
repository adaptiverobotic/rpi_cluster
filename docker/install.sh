#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

# List of ip addresses by role
leader_file="${ASSETS}/leader"
manager_file="${ASSETS}/manager"
worker_file="${ASSETS}/worker"

send_assets() {
  echo "Sending assets to each node"

  # SCP setup script to each node
  $UTIL scp_specific_nodes $IPS $(pwd)/setup.sh
}

install_docker() {
  echo "Installing docker on all nodes"

  # Install docker on all nodes
  $UTIL ssh_specific_nodes $IPS ./setup.sh install_docker
}

select_leader() {
  echo "Selecting leader node"

  # Write leader ip out to a file
  echo "Selecting leader node"
  echo $(head -n 1 $IPS) > $leader_file

  # Capture leader_ip
  leader_ip=$(cat $leader_file)
  echo "Leader will be: $leader_ip"
  echo "Make sure that it's ip address does not change"
  echo "Either assign it a static ip or reserve it's dhcp lease"
}

select_workers() {
  echo "Generating list of worker nodes"

  # Delete old worker file
  rm -fv $worker_file

  # Get all but the first ip in the $IPS file.
  # NOTE - This will not be our final list of
  # workers. When we generate the list of managers
  echo "Generating list of worker node ips"
  echo $(tail -n +2 $IPS) | tr " " "\n" > $worker_file

  echo "The following is a list of all non-leader node(s)"
  echo "NOTE: Half of these will be promoted to managers to meet quarum"
  echo $(cat $worker_file)
}

# We will take half of the workers ip addresses
# and promote them to manager status. We do this`
# to comply with docker's 'quorum' rules. That is,
# for n nodes, (n+1) / 2 of them should be managers.
# This provides pretty good fault tolerance.
# In the event that the leader goes down,
# we won't lose the entire swarm.
select_managers() {
  echo "Generating list of manager nodes"

  # Delete old manager file
  rm -fv $manager_file

  # Get number of workers
  num_workers=$( $UTIL num_lines $worker_file )

  # Make half of them managers
  num_managers=$(( $num_workers / 2 ))

  # (n+1) / 2 = quorum
  echo "There are $num_workers worker(s)"
  echo "Promoting $num_managers worker(s) to manager(s)"

  # Write their ips out to file
  echo $(head -$num_managers $worker_file) > $manager_file

  # If there are nodes to read in
  if [[ $num_managers > 0 ]]; then
    # Loop through each manager
    # and remove it from worker_file
    echo "The following nodes will be managers:"
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
  echo "The following nodes will be workers:"
  cat $worker_file
}

download_tokens() {
  echo "Downloading join-token scripts from leader"

  # Download the join token scripts to this devce
  $UTIL my_scp_get_file $COMMON_USER@$leader_ip $(pwd)/assets/ manager_join_token.sh
  $UTIL my_scp_get_file $COMMON_USER@$leader_ip $(pwd)/assets/ worker_join_token.sh
}

disband_swarm() {
  echo "Disbanding old swarm"

  # Loop through each node
  # and remove it from existing swarm.
  # We have to remove the leader last
  echo "Removing all nodes from existing swarm"
  $UTIL ssh_specific_nodes $IPS ./setup.sh leave_swarm
}

init_swarm() {

  # Initialize the swarm
  echo "Initializing new swarm"

  # NOTE - Maybe use head just in case. Just to make sure we only
  # read in one ip address. If somehow this file gets edited, and a
  # second valid ip address is inserted, the script will fail
  $UTIL ssh_specific_nodes $leader_file ./setup.sh init_swarm
}

join_swarm() {
  echo "Adding nodes to swarm"

  num_managers=$( $UTIL num_lines $manager_file)
  num_workers=$( $UTIL num_lines $worker_file)


  if [[ $num_workers > 0 ]]; then
    # Send join-tokens to all nodes
    echo "Sending worker join-token script to workers"
    $UTIL scp_specific_nodes $worker_file $(pwd)/assets/worker_join_token.sh

    # Execute join-token  script
    echo "Adding workers to swarm"
    $UTIL ssh_specific_nodes $worker_file ./worker_join_token.sh

  else
    echo "No workers to add to swarm"
  fi

  if [[ $num_managers > 0 ]]; then
    echo "Sending manager join-token script to managers"
    $UTIL scp_specific_nodes $manager_file $(pwd)/assets/manager_join_token.sh

    echo "Adding managers to swarm"
    $UTIL ssh_specific_nodes $manager_file ./manager_join_token.sh
  else
    echo "No managers to add to swarm"
  fi
}

new_swarm() {
  echo "Installing Docker and creating swarm"

  # Clear home directories
  $UTIL clean_workspace $IPS

  # Send setup files
  send_assets

  # Install docker
  install_docker

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
}

$@

#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Get list of ips
leader_file="${ASSETS}/leader"
worker_file="${ASSETS}/worker"

# Alias to import util script
# util="/bin/bash ../util/util.sh"

send_assets() {
  echo "Sending asset files to nodes"

  # SCP setup script to each node
  $UTIL scp_specific_nodes $IPS $(pwd)/setup.sh
}

install_docker() {
  echo "Install docker on all nodes"

  # Install docker on all nodes
  $UTIL ssh_specific_nodes $IPS ./setup.sh install_docker
}

select_leader() {
  echo "Selecting leader node"

  # Read leader ip into a file
  echo "Selecting leader node"
  echo $(head -n 1 $IPS) > $leader_file

  # Capture leader_ip
  leader_ip=$(cat $leader_file)
  echo "Leader will be: $leader_ip"
  echo "Make sure that it's ip address does not change"
  echo "Either assign in a static ip or reserve it's dhcp less"
}

select_managers() {
  echo "Generating list of manager nodes"

  # TODO - Read first two lines as managers
  # this way if one leader goes out we aren't screwed
}

select_workers() {
  echo "Generating list of worker nodes"

  # TODO - Do we want to have the works list
  # overlap with managers? This probably makes
  # more sense because this is an initial install
  # script. All managerial tasks will be handled
  # by the leader. We can consider all managers
  # that are not the leader works for the purpose
  # of this install.
  echo "Generating list of worker node ips"
  echo $(tail -n +2 $IPS) | tr " " "\n" > $worker_file
}

download_tokens() {
  echo "Pulling join tokens from leader"

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
  $UTIL ssh_specific_nodes $worker_file ./setup.sh leave_swarm
  $UTIL ssh_specific_nodes $leader_file ./setup.sh leave_swarm
}

init_swarm() {

  # Initialize the swarm
  echo "Initializing new swarm"

  # NOTE - Maybe used head just in case. Just to make sure we only
  # read in one ip address. If somehow this file gets edited, and a
  # second valid ip address is inserted, the script will fail
  $UTIL ssh_specific_nodes $leader_file ./setup.sh init_swarm
}

join_swarm() {
  echo "Adding nodes to swarm"

  # Add all nodes to swarm
  echo "Each node joining swarm"
  $UTIL scp_specific_nodes $worker_file $(pwd)/assets/worker_join_token.sh

  # NOTE - This seems to hang. Not sure if this has to do with
  # my connection, or if docker is doing a lot as it removed leaders.
  $UTIL ssh_specific_nodes $worker_file /bin/bash worker_join_token.sh
}

echo "Installing Docker"

# Clear home directories
$UTIL clean_workspace $IPS

# Send setup files
send_assets

# Install docker
install_docker

# Pick a leader
select_leader

# Select the managers
select_managers

# Select the workers
select_workers

# Disband old swarms
disband_swarm

# Create new swarm
init_swarm

# Download join tokens
download_tokens

# Add nodes to swarm
join_swarm

#!/bin/bash
set -e

install_docker() {
  user=$1

  echo "Installing docker on $user"

  # Check that docker is installed
  if docker &> /dev/null; then
    echo "Docker is already installed"
  else
    # Allow docker command with no sudo
    curl -sSL https://get.docker.com | sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $user

    echo "Finished Docker install process"
  fi
}

uninstall_docker() {
  echo ""
  # NOTE - DO NOT INSTALL DOCKER FROM apt-get
  # IT IS A NIGHTMARE TO UNINSTALL
}

leave_swarm() {
  # Check if a node is in a swarm or not.
  if docker swarm leave --force &> /dev/null; then
    echo "Node left the swarm"
  else
    echo "This node was not part of a swarm"
  fi
}

init_swarm() {

  # Get this device's ip address
  ip=$1

  # Make a new swarm.
  echo "Initializing swarm, advertising ip: $ip"
  docker swarm init --advertise-addr $ip

  # Get the join-token for workers and managers
  echo "Generating join tokens for joining the new swarm"
  docker swarm join-token worker | grep "docker" > worker_join_token.sh
  docker swarm join-token manager | grep "docker" > manager_join_token.sh

  # Make the tokens runnable scripts
  chmod 777 worker_join_token.sh
  chmod 777 manager_join_token.sh
}

#-------------------------------------------------------------------------------

user=$1

"$@"

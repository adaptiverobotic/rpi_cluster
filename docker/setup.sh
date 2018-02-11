#!/bin/bash
set -e

install_docker() {
  echo "Installing docker on $user"

  # Allow docker command with no sudo
  curl -sSL https://get.docker.com | sh
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker $user

  echo "Finished Docker install process"
}

#-------------------------------------------------------------------------------

uninstall_docker() {
  echo ""
  # NOTE - DO NOT INSTALL DOCKER FROM apt-get
  # IT IS A NIGHTMARE TO UNINSTALL
}

#-------------------------------------------------------------------------------

init_swarm() {

  # Get this device's ip address
  ip=$1

  # Make a new one
  echo "Initializing swarm, advertising ip: $ip"
  docker swarm init --advertise-addr $ip

  # Get the join-token for workers and managers
  echo "Generating join tokens for joining the new swarm"
  worker_join_token=$(docker swarm join-token worker | grep "docker")
  manager_join_token=$(docker swarm join-token manager | grep "docker")

  # Send the tokens back to the client
}

#-------------------------------------------------------------------------------

user=$1

"$@"

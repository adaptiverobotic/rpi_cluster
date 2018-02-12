#!/bin/bash
set -e

install_docker() {
  user=$1
  reinstall=$2

  echo "Installing docker on $user"
  echo "Checking if docker is already installed"

  # Check that docker is installed
  if docker; then
    echo "Docker is already installed"
  else
    echo "Downloading installscript from docker.com"

    # Download it and pipe in into /bin/sh (run it)
    curl -sSL https://get.docker.com | sh

    # Enable docker
    echo "Enabling docker daemon"
    sudo systemctl enable docker

    # Start docker
    echo "Starting docker daemon"
    sudo systemctl start docker

    # Allow docker command with no sudo
    echo "Enabling sudo-less docker"
    sudo usermod -aG docker $user

    echo "Finished Docker install process"
  fi
}

uninstall_docker() {
  echo "Uninstalling docker"
  # Stop docker
  echo "Stopping docker daemon"
  sudo systemctl start docker

  # Remove from apt-get
  echo "Purging docker"
  sudo apt-get purge docker-ce -y

  # Remove files it created
  # Containers, images, etc
  echo "Removing left over files"
  sudo rm -rfv /var/lib/docker
}

reinstall_docker() {
  echo "Reinstalling docker"
  uninstall_docker $@
  install_docker $@
}

leave_swarm() {
  echo "Leaving swarm"

  # Check if a node is in a swarm or not.
  # TODO - Maybe we should find a better way of
  # making sure that we are removed. Because if we
  # don't successfully leave, but continue the script,
  # then we will run into issues.
  if docker swarm leave --force; then
    echo "Node left the swarm"
  else
    echo "This node was not part of a swarm or could not leave"
  fi
}

init_swarm() {

  # Get this device's ip address
  ip=$1

  # NOTE - Maybe make sure we have left?

  # Make a new swarm.
  echo "Initializing swarm, advertising ip: $ip"
  docker swarm init --advertise-addr $ip

  # Get the join-token commands for workers and managers and pipe
  # the output into respective script files. These script files
  # will be sent to and run on the appropriate nodes
  echo "Generating join tokens for joining the new swarm"
  docker swarm join-token worker | grep "docker" > worker_join_token.sh
  docker swarm join-token manager | grep "docker" > manager_join_token.sh

  # Make the tokens runnable scripts
  chmod 777 worker_join_token.sh
  chmod 777 manager_join_token.sh

  # We will leave the scripts in our home directory. The sysadmin machine
  # that is facilitating the install will expect them to be there. The sysadmin
  # will SCP them from this device's home directly to its local working directory
  # and them ship them out to the appropriate nodes in the cluster.
}

#-------------------------------------------------------------------------------

user=$1

$@

#!/bin/bash
set -e

#-------------------------------------------------------------------------------

# Install docker via their install
# script. We check if docker is
# installed. If it is, then we
# skip the installation process.
install_docker() {
  echo "Installing docker locally"


  # Check that docker is installed
  if docker ps; then
    echo "Docker is already installed"

  # We need to install it
  else
    echo "Downloading install script from docker.com"

    # Download it and pipe in into /bin/sh (run it)
    curl -sSL https://get.docker.com | sh

    # Enable docker
    echo "Enabling docker daemon"
    sudo systemctl enable docker

    # Start docker
    echo "Starting docker daemon"
    sudo systemctl start docker

    # Allow docker command to execute with no sudo
    echo "Enabling sudo-less docker"
    sudo usermod -aG docker $(whoami)

    # Must log out for changes to take place

    echo "Finished Docker install process"
  fi
}

#-------------------------------------------------------------------------------

# Removes docker from a node.
# We first check and make sure
# that it is installed before Uninstalling.
uninstall_docker() {
  echo "Uninstalling docker"

  # Check if the machine recognizes
  # the docker command
  if docker ps; then
    # Remove from apt-get
    echo "Purging docker"
    sudo apt-get purge docker-ce -y

    # Remove files it created
    # Containers, images, etc
    echo "Removing left over files"
    sudo rm -rf /var/lib/docker

  # No work to be done
  else
    echo "Docker is not installed"
  fi
}

#-------------------------------------------------------------------------------

start_portainer() {
  echo "Starting portainer"

  password=$1

  # Create necessary volume
  docker volume create portainer

  # Create admin password secret
  echo -n $password | docker secret create portainer-pass -

  # Launch service
  docker service create \
  --detach \
  --name portainer \
  --secret portainer-pass \
  --mode global \
  --constraint 'node.role == manager' \
  --publish mode=host,target=9000,published=9000 \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,source=portainer,target=/data \
  portainer/portainer \
  --admin-password-file '/run/secrets/portainer-pass' \
  -H unix:///var/run/docker.sock
}

#-------------------------------------------------------------------------------

# Utility function that makes sure
# we are uninstalling and reinstalling.
# This is more diagnostic than anything else.
reinstall_docker() {
  echo "Reinstalling docker"
  uninstall_docker
  install_docker
}

#-------------------------------------------------------------------------------

# Removes a node from
# a preexisting swarm.
leave_swarm() {
  echo "Leaving swarm"

  # Check if a node is in a swarm or not.
  # TODO - Maybe we should find a better way of
  # making sure that we are removed. Because if we
  # don't successfully leave, but continue the script,
  # then we will run into issues.
  if docker swarm leave --force; then
    echo "Successfully left swarm"
  else
    echo "This node was not part of a swarm or could not leave"
  fi
}

#-------------------------------------------------------------------------------

# Initializes a new swarm with
# this device (node) as the leader.
# We then generate join scripts
# that other nodes will execute to
# join this node's swarm.
init_swarm() {

  # Get this device's ip address
  ip=$(hostname -I | awk '{print $1}')

  # Make a new swarm.
  echo "Initializing swarm, advertising ip: $ip"

  # TODO - Maybe pipe this to /dev/null
  # for security purposes??
  docker swarm init --advertise-addr "$ip"

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
  # that is facilitating the install process will expect them to be there. The sysadmin
  # will SCP them from this device's home directly to its local working directory
  # and them ship them out to the appropriate nodes in the cluster.
}

#-------------------------------------------------------------------------------

"$@"

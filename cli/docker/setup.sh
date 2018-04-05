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
    echo "Pruning system (Deleting all old docker objects)"

    # Delete everything
    docker system prune \
    --all              \
    --volumes          \
    --force

    echo "Successfully deleted all old docker objects"

  # We need to install it
  else
    echo "Downloading install script from docker.com"

    # TODO - Manually install Docker, they say this script
    # will stop supporting Ubuntu 16.04

    # Download it and pipe in into /bin/sh (run it)
    # NOTE - This script presents issues if the
    # script cannot determine the host operating system.
    # I think I ran into this issue with Raspbian Desktop.
    # To expand to more linux distros, we would need to
    # manually add the repo, etc.
    # See - https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository
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

    # Delete everything
    docker system prune \
    --all               \
    --volumes           \
    --force

    # Remove with package manager
    echo "Purging docker"
    sudo apt-get purge docker-ce -y

    # Remove files it created
    # Containers, images, etc
    echo "Removing left over files"
    if sudo umount -R /var/lib/docker -l; then
      :
    fi

    # sudo rm -rf /var/lib/docker

    # TODO - Remove /etc/docker
    # the problem right now is the
    # permission on that file is denied.
    # It might not be a "docker" file.

  # No work to be done
  else
    echo "Docker is not installed"
  fi
}

#-------------------------------------------------------------------------------

# Utility function that makes sure
# we are uninstalling and reinstalling.
# This is more diagnostic than anything else.
reinstall_docker() {
  echo "Reinstalling docker"
  uninstall_docker
  install_docker
  echo "Successfully reinstalled docker"
}

#-------------------------------------------------------------------------------

main() {
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

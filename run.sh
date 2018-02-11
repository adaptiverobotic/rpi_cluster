#!/bin/bash
set -e

# Make sure every script is
# runnable with ./script_name.sh syntax
chmod 777 **/*.sh

# We must install this dependency
# outside of the dependency script
# because we use sshpass in util
# to ssh into all nodes without password
# sudo apt-get install sshpass

ip_list() {
  echo "Generating list of ips"

  # Build ip address list
  ./ip/list.sh
}

ssh_keys() {
  echo "Generating ssh keys and copying it to all nodes"

  # Enable passwordless ssh
  ./ssh/install.sh
}

hostname() {
  echo "Changing each node's hostname to match a specified pattern"

  # Change all the hostnames
  ./hostname/change.sh
}

dependencies() {
  echo "Installing dependencies on all nodes"

  # Install dependencies
  ./dependencies/install.sh
}

firewall() {
  echo "Configuring each nodes' firewall"

  # Configure firewall
  ./ufw/install.sh
}

nas() {
  echo "Mounting each node's home folder as a network attached storage"

  # Setup network attached storage
  ./samba/install.sh
}

docker() {
  echo "Creating docker cluster"

  # Initialize docker swarm
  ./docker/install.sh
}

kubernetes() {
  echo "Creating kubernetes cluster"
}

deploy() {

  # Just for clarity
  provider=$1
  app_dir=$2

  echo "Deploying test app to $provider cluster"

  # Deploy test application
  ./$1/deploy.sh $2 ${@:3}
}

init() {
  echo "Initializing general cluster settings"

  ip_list

  ssh_keys

  hostname

  dependencies

  firewall

  nas
}

docker_cluster() {
  init

  docker
}

$@

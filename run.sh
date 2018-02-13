#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

# NOTE - run.sh is ALWAYS in the root
# directory of this project. If
# not, all environment variables
# will break in subprocesses.
export ROOT_DIR="$( pwd )"

# Environment variables
export APPS="$ROOT_DIR/apps"
export ASSETS="$ROOT_DIR/assets"
export COMMON_HOST="$(cat $ASSETS/hostname)"
export COMMON_PASS="$(cat $ASSETS/password)"
export COMMON_USER="$(cat $ASSETS/user)"
export LOG_DIR="${ROOT_DIR}/.logs"
export IPS="$ROOT_DIR/assets/ips"
export UTIL="/bin/bash $ROOT_DIR/util/util.sh"

# Make sure every script is
# runnable with ./script_name.sh syntax
# That way the appropriate shell
# (bash, sh, expect) is run for a given script
chmod 777 **/*.sh

#-------------------------------------------------------------------------------

# Generates a list of ip addresses
# of all of the nodes that will
# participate in the swarm. Currently
# we are scanning the network and adding
# ip adddresses that match a certain prefix.
# Right now, we are using the Raspberry Pi
# prefix, butit works for any.
ip_list() {
  echo "Generating list of ips"

  # Build ip address list
  ./ip/list.sh
}
#-------------------------------------------------------------------------------

# Generates ssh keys and ships
# them to all nodes to that we
# do not have to type in our password
# when we ssh into our cluster. We
# can eventually disable password
# authenticatio all together to make our
# cluster more secure.
ssh_keys() {
  echo "Generating ssh keys and copying it to all nodes"

  # Enable passwordless ssh
  ./ssh/install.sh $@
}

#-------------------------------------------------------------------------------

hostname() {
  echo "Changing each node's hostname to match a specified pattern"

  # Change all the hostnames
  ./hostname/install.sh $1
}

#-------------------------------------------------------------------------------

dependencies() {
  echo "Installing dependencies on all nodes"

  # Install dependencies
  ./dependencies/install.sh
}

#-------------------------------------------------------------------------------

firewall() {
  echo "Configuring each nodes' firewall"

  # Configure firewall
  ./ufw/install.sh
}

#-------------------------------------------------------------------------------

install_samba() {
  echo "Setting up each node as a network attached storage"

  # Setup network attached storage
  ./samba/install.sh
}

#-------------------------------------------------------------------------------

uninstall_samba() {
  echo "Uninstalling samba from cluster"

  # Uninstall samba from all nodes
  ./samba/uninstall.sh
}

install_docker() {
  echo "Creating docker cluster"

  # Initialize docker swarm
  ./docker/install.sh new_swarm
}

#-------------------------------------------------------------------------------

uninstall_docker() {
  echo "Uninstalling docker from cluster"

  # Remove docker from nodes
  ./docker/uninstall.sh
}

#-------------------------------------------------------------------------------

install_kubernetes() {
  echo "Creating kubernetes cluster"

  # Initialize kubernetes cluster
  ./kubernetes/install.sh
}

#-------------------------------------------------------------------------------

uninstal_kubernetes() {
  echo "Uninstalling kubernetes from cluster"

  # Remove kubernetes from nodes
  ./kubernetes/uninstall.sh
}

#-------------------------------------------------------------------------------

restart_cluster() {
  echo "Restarting the cluster"

  ${UTIL} reboot_nodes
}

#-------------------------------------------------------------------------------

deploy() {

  # Deploys an application to
  # a given cluster provider
  # (docker swarm or kuberneters)

  # Just for clarity
  provider=$1
  app_dir=$2
  args=${@:3}

  echo "Deploying app to $provider cluster"

  # Deploy test application
  ./$provider/deploy.sh $app_dir $args
}

#-------------------------------------------------------------------------------

init() {
  provider=$1
  echo "Initializing cluster settings for: $provider"

  # Create a global list of ip
  # addresses that represent the
  # list of nodes that will be in
  # the cluster
  ip_list $provider

  # Generate ssh keys, and ship
  # the public keys to each node
  # to enable passwordless access
  ssh_keys install

  # Change all of the hostnames
  # in the cluster to some common
  # naming convention
  hostname $provider

  # TODO - Download dependencies
  # depending on what we are deploying.
  # Example, we do not want to download
  # kubernetes if we are deploying docker swarm
  dependencies $provider

  # TODO - Open ports depending on
  # what we are deploying. Example, if
  # we are only deploying SAMBA, then we
  # do not need to open docker ports

  # firewall $provider
}

#-------------------------------------------------------------------------------

# Sets up cluster as a docker
# swarm cluster, and deploys
# Portainer to the cluster for
# easy docker swarm management
docker_cluster() {
  init docker

  install_docker

  # Deploy Portainer for easy swarm management
  deploy docker service $ROOT_DIR/docker/service/portainer/

  # Check that the cluster is up
  $UTIL delayed_action 10 "Health_Check" curl $(cat assets/leader):9000

  # Deploy test application as proof of concept
  # deploy docker service $ROOT_DIR/apps/test_app/
}

#-------------------------------------------------------------------------------

# Sets up cluster as a
# kubernetes cluster
kubernetes_cluster() {
  init kubernetes

  install_kubernetes

  deploy kubernetes service $ROOT_DIR/test_app/
}

#-------------------------------------------------------------------------------

# Sets up each node in the
# the cluster as a Network
# Attached Storage (NAS).
samba_cluster() {
  init samba

  install_samba
}

"$@"

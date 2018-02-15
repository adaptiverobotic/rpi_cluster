#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

declare_variables() {
  # NOTE - run.sh is ALWAYS in the root
  # directory of this project. If
  # not, all environment variables
  # will break in subprocesses.
  export ROOT_DIR="$( pwd )"

  # Environment variables
  export ASSETS="$ROOT_DIR/assets"
  export COMMON_HOST="$(cat $ASSETS/hostname)"
  export COMMON_PASS="$(cat $ASSETS/password)"
  export COMMON_USER="$(cat $ASSETS/user)"
  export IPS="$ASSETS/ips"
  export LOG_DIR="${ROOT_DIR}/.logs"
  export SYNC_MODE="false"
  export UTIL="/bin/bash $ROOT_DIR/util/util.sh"

  # Make sure every script is
  # runnable with ./script_name.sh syntax
  # That way the appropriate shell
  # (bash, sh, expect) is run for a given script
  chmod +x **/*.sh
}

#-------------------------------------------------------------------------------

# Generates a list of ip addresses
# of all of the nodes that will
# participate in the cluster. Currently
# we are scanning the network and adding
# ip adddresses that match a certain prefix.
# Right now, we are using the Raspberry Pi
# prefix, but it works for any.
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
  echo "Generating ssh keys and copying to all nodes"

  # Enable passwordless ssh
  ./ssh/install.sh install
}

#-------------------------------------------------------------------------------

hostname() {
  local provider=$1
  echo "Changing each node's hostname"

  # Change all the hostnames
  ./hostname/install.sh change_hostnames $provider
}

#-------------------------------------------------------------------------------

# Install dependencies
dependencies() {
  local provider=$1

  echo "Installing dependencies on all nodes"
  ./dependencies/install.sh $provider
}

#-------------------------------------------------------------------------------

# Configure firewall for a
# given provider
firewall() {
  local provider=$1

  echo "Configuring each nodes' firewall"
  ./ufw/install.sh $provider
}

#-------------------------------------------------------------------------------

# Install either docker,
# kubernetes, or samba on
# entire cluster
install() {
  local provider=$1; shift

  echo "Installing "$@" on cluster"
  ./$provider/install.sh "$@"
}

#-------------------------------------------------------------------------------

# Power off and power on
# all nodes in cluster
restart_cluster() {
  echo "Restarting the cluster"

  $UTIL reboot_nodes
}

#-------------------------------------------------------------------------------

init() {
  provider=$1
  echo "Initializing cluster settings for: $provider"

  # Create a global list of ip
  # addresses that represent the
  # list of nodes that will be in
  # the cluster
  ip_list

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
  install docker swarm portainer

  # Check that the cluster's portainer page is up is up
  local portainer_url="http://$(cat assets/leader):9000"
  $UTIL health_check 3 10 "Health_Check" "curl --silent --output /dev/null $portainer_url"
  $UTIL display_entry_point $portainer_url
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

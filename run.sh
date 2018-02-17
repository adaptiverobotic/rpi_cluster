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
  export DEV_MODE=false
  export IPS="$ASSETS/ips"
  export LAST_DEPLOYMENT="$ASSETS/last_deployment"
  export LOG_DIR="${ROOT_DIR}/.logs"
  export SYNC_MODE="false"
  export UTIL="/bin/bash $ROOT_DIR/util/util.sh"

  # This is a hidden dir
  # so it won't get pulled from
  # github, so let's make sure
  # that it is present so we don't
  # error out when we try to write
  # files to this directory
  mkdir -p $LOG_DIR

  # Make sure every script is
  # runnable with ./script_name.sh syntax
  # That way the appropriate shell
  # (bash, sh, expect) is run for a given script
  chmod +x **/*.sh
}

#-------------------------------------------------------------------------------

# Move old logs to an archive
# and clear the logs to make
# space for new log files
prepare_logs() {
  $UTIL archive_old_logs
  $UTIL clear_logs
}

#-------------------------------------------------------------------------------

# Writes the date and time out to
# a file that represents when this deployment
# was kicked off. Used for management.
create_deployment_timestamp() {
  date '+%Y-%m-%d %H:%M:%S' > "$LAST_DEPLOYMENT"
}

#-------------------------------------------------------------------------------

# Configure firewall for a
# given provider such as docker
# swarm, kubernetes.
firewall() {
  local provider=$1

  echo "Configuring each nodes' firewall for: $provider"
  ./ufw/install.sh $provider
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
  ./ssh/install.sh
}

# Everything above this line will not have an api binding. They are auxiliary
# functoins that make the applicaiton work correctly. But, we do not want
# these behaviors exosed.
#===============================================================================

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

# Changes the hostname on all
# nodes to match a specified pattern.
hostname() {
  local provider=$1

  echo "Changing each node's hostname"
  ./hostname/install.sh change_hostnames $provider
}

#-------------------------------------------------------------------------------

# Install dependencies on
# all nodes in cluster
dependencies() {
  local provider=$1

  echo "Installing dependencies on all nodes"
  ./dependencies/install.sh install $provider
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

# Reboot all nodes
# in cluster
reboot_cluster() {
  echo "Rebooting the cluster"

  $UTIL reboot_nodes
}

#-------------------------------------------------------------------------------

# Power off and power on
# all nodes in cluster
restart_cluster() {
  echo "Restarting the cluster"
}

# NOTE - Everything below this line will not have an api binding. That is, they are
# here for development purposes. But, they will be reimplemented on the api
# side with better error handling between steps.
#==============================================================================

init() {
  provider=$1
  echo "Initializing cluster settings for: $provider"

  # ip_list
  ssh_keys
  hostname $provider
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
  local portainer_url="http://$(cat docker/assets/leader):9000"
  $UTIL health_check 3 10 "Health_Check" "curl --silent --output /dev/null $portainer_url"
  $UTIL display_entry_point $portainer_url
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  $UTIL print_in_color "light_cyan" "THIS IS MESSAGE"

  prepare_logs
  create_deployment_timestamp
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

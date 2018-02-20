#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Globals
declare_variables() {

  # Core globals
  export ROOT_DIR="$( pwd )"
  export ASSETS="$ROOT_DIR/assets"
  export UTIL="/bin/bash $ROOT_DIR/util.sh"

  # Logging
  export THIS_DEPLOYMENT="$ASSETS/temp/this_deployment"
  export LAST_DEPLOYMENT="$ASSETS/temp/last_deployment"
  export LOG_DIR="${ROOT_DIR}/.logs"

  # Lists of ip addresses
  # for different servers
  export IPS="$ASSETS/ips/cluster"
  export DHCP_IP_FILE="$ASSETS/ips/dhcp"
  export NAS_IP_FILE="$ASSETS/ips/nas"
  export SYSADMIN_IP_FILE="$ASSETS/ips/sysadmin"

  # Dev purporses
  export SYNC_MODE="false"
  export DEV_MODE=false
}

#-------------------------------------------------------------------------------

# Reads in common credentials
# such as user and password
read_in_common_credentials() {

  # Read them in from the files
  local cred="$ASSETS/credentials"
  local host="$(cat $cred/hostname)"
  local user="$(cat $cred/user)"
  local pass="$(cat $cred/password)"

  # Make sure they are all valid.
  # If not, these function error out.
  $UTIL valid_hostname $host
  $UTIL valid_password $pass
  $UTIL valid_user     $user

  # If they are all valid
  # export them as environment
  # variables for global use
  export COMMON_HOST=$host
  export COMMON_USER=$user
  export COMMON_PASS=$pass
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
  ./ip/list.sh
  $UTIL print_success "SUCCESS: " "ip lists generated"
}

#-------------------------------------------------------------------------------

# Move old logs to an archive
# and clear the logs to make
# space for new log files
prepare_logs() {
  local deployment=$(date '+%Y-%m-%d %H:%M:%S')

  echo "Preparing logs for deployment"
  $UTIL archive_old_logs
  $UTIL clear_logs
  echo "$deployment" > "$LAST_DEPLOYMENT"
  $UTIL print_success "SUCCESS: " "Logs are ready for deployment"

}

#-------------------------------------------------------------------------------

# Configure firewall for a
# given provider such as docker
# swarm, kubernetes.
firewall() {
  local provider=$1

  echo "Configuring each nodes' firewall for: $provider"
  ./ufw/install.sh $provider
  $UTIL print_success "SUCCESS: " "Configured firewall for $provider"
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
  ./ssh/install.sh
  $UTIL print_success "SUCCESS: " "Successfully administered new ssh keys"
}

#-------------------------------------------------------------------------------

# Install dependencies on
# all nodes in cluster
dependencies() {
  local provider=$1

  echo "Installing dependencies on all nodes for: $docker"
  ./dependencies/install.sh install $provider
  $UTIL print_success "SUCCESS: " "Installed dependencies for: $provider"
}

# Everything above this line will not have an api binding. They are auxiliary
# functoins that make the applicaiton work correctly. But, we do not want
# these behaviors exosed.
#===============================================================================

# Changes the hostname on all
# nodes to match a specified pattern.
hostname() {
  local provider=$1

  echo "Changing each node's hostname"
  ./hostname/install.sh change_hostnames $provider
  $UTIL print_success "SUCCESS: " "All hostnames changed"
}

#-------------------------------------------------------------------------------

# Install either docker,
# kubernetes, or samba on
# entire cluster
install() {
  local provider=$1; shift

  echo "Installing "$@" on cluster"
  ./$provider/install.sh "$@"
  $UTIL print_success "SUCCESS: " "Installed $provider on cluster"
}

#-------------------------------------------------------------------------------

# Uninstall either docker,
# kubernetes, or samba on
# entire cluster
uninstall() {
  local provider=$1; shift

  echo "Uninstalling "$@" on cluster"
  ./$provider/install.sh "$@"
  $UTIL print_success "SUCCESS: " "Removed $provider from cluster"
}

#-------------------------------------------------------------------------------

# Just installs the
# docker engine on
# the cluster
docker_engine() {
  init docker
  install docker docker_daemon
  $UTIL print_success "SUCCESS: " "Docker engine installed"
}

#-------------------------------------------------------------------------------

# Sets up cluster as a docker
# swarm cluster, and deploys
# Portainer to the cluster for
# easy docker swarm management
docker_swarm() {
  init docker
  install docker swarm portainer

  # Check that the cluster's portainer page is up is up
  local portainer_url="http://$(cat docker/assets/leader):9000"
  $UTIL health_check 3 10 "Health_Check" "curl --silent --output /dev/null $portainer_url"
}

#-------------------------------------------------------------------------------

nextcloud() {
  ./nextcloud/install.sh start_nextcloud

  # Check that the cluster's portainer page is up is up
  local nextcloud_url="http://$(cat ${ASSETS}/ips/nas)"
  $UTIL health_check 3 60 "Health_Check" "curl --silent --output /dev/null $nextcloud_url"
  # $UTIL display_entry_point $nextcloud_url
}

# NOTE - Everything below this line will not have an api binding. That is, they are
# here for development purposes. But, they will be reimplemented on the api
# side with better error handling between steps.
#==============================================================================

init() {
  provider=$1
  echo "Initializing cluster settings for: $provider"
  hostname $provider
  dependencies $provider
  firewall $provider
  $UTIL print_success "SUCCESS: " "Cluster initialized"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables
  prepare_logs
  read_in_common_credentials
  ip_list
  # "$@"
}

#-------------------------------------------------------------------------------

main "$@"

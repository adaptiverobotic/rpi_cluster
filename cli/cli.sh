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

  # Lists of ip addresses
  # for different clusters
  export IP_DIR="$ASSETS/ips"
  export ALL_IPS_FILE="$ASSETS/ips/all"
  export IPS="$ASSETS/ips/cluster"
  export DHCP_IP_FILE="$ASSETS/ips/dhcp"
  export NAS_IP_FILE="$ASSETS/ips/nas"
  export SYSADMIN_IP_FILE="$ASSETS/ips/sysadmin"

  # Dev purporses
  export DEV_MODE=false
  export TEMP_DIR="$ASSETS/temp"

  # Logging
  export THIS_DEPLOYMENT="$ASSETS/temp/this_deployment"
  export LAST_DEPLOYMENT="$ASSETS/temp/last_deployment"
  export LOG_DIR="$ROOT_DIR/.logs"
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
  $UTIL valid_user     $user
  $UTIL valid_password $pass

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
  ./ip/list.sh generate_list
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

#-------------------------------------------------------------------------------

# Changes the hostname on all
# nodes to match a specified pattern.
hostname() {
  local provider=$1

  echo "Changing each node's hostname"
  ./hostname/install.sh change_hostnames $provider
  $UTIL print_success "SUCCESS: " "All hostnames changed"
}

#-------------------------------------------------------------------------------

# Just installs the
# docker engine on
# the cluster
install_docker() {
  ./docker/install.sh reinstall_docker
  $UTIL print_success "SUCCESS: " "Docker engine installed"
}

#-------------------------------------------------------------------------------

# Only allow install,
# reinstall and uninstall
validate_arg() {
  local method=$1

  # Only accept the following methods
  if [[ $method != install_* ]]   && \
     [[ $method != reinstall_* ]] && \
     [[ $method != uninstall_* ]]; then

       $UTIL print_error "ERROR: " "Only methods 'install_*', 'uninstall_*' , 'reinstall_*' supported"
       return 1
  fi
}

#-------------------------------------------------------------------------------

swarms() {
  local method=$1

  ./swarm/install.sh $method $DHCP_IP_FILE
  ./swarm/install.sh $method $NAS_IP_FILE
  ./swarm/install.sh $method $IPS

  # TODO - Change hostnames here
}

# Everything above this line will not have an api binding. They are auxiliary
# functions that make the applicaiton work correctly. But, we do not want
# these behaviors exosed.
#===============================================================================

# Install, uninstall
# or reinstall nextcloud
nextcloud() {
  local method=$1
  local nextcloud_url="http://$(head -n 1 $NAS_IP_FILE)"

  ./nextcloud/install.sh $method
  $UTIL health_check 3 30 $nextcloud_url
  $UTIL display_entry_point $nextcloud_url $COMMON_USER
}

#-------------------------------------------------------------------------------

# Install, uninstall
# or reinstall pihole
pihole() {
  local method=$1
  local pihole_url="http://$(cat $DHCP_IP_FILE)/admin"

  ./pihole/install.sh $method
  $UTIL health_check 3 10 $pihole_url
  $UTIL display_entry_point $pihole_url
}

#-------------------------------------------------------------------------------

samba() {
  local method=$1

  validate_arg $method
  ./samba/install.sh $method
}

#-------------------------------------------------------------------------------

# Install, uninstall
# or reinstalls network
# address transation for
# the entire environment
nat() {
  local method=$1

  ./nat/install.sh $method

  # If we just installed or reinstalled,
  # Check that all 3 servers can be
  # reach from a single hostname
  if [[ $method == install_* ]]    ||
     [[ $method == reinstall_* ]]; then

    local ip=$($UTIL my_ip)
    local $swarm_url="$ip:9000"
    local $pihole_url="$ip:8081/admin"
    local $nextcloud_url="$ip:8000"

    # Health check on entire system
    $UTIL health_check 3 10 $swarm_url
    $UTIL health_check 3 10 $pihole_url
    $UTIL health_check 3 10 $nextcloud_url

    $UTIL print_success "SUCCESS: " "System up and healthy"
  fi
}

#-------------------------------------------------------------------------------

# Stands up entire
# environment
magic() {
  ip_list
  ssh_keys
  install_docker install
  swarms         install_swarm
  samba          install_samba
  pihole         install_pihole
  nextcloud      install_nextcloud
}

#-------------------------------------------------------------------------------

main() {
  declare_variables
  prepare_logs
  read_in_common_credentials
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

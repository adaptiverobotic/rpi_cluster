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
  export BIN="$ROOT_DIR/bin"
  export UTIL="$ROOT_DIR/util/util.sh"

  # Lists of ip addresses
  # for different clusters
  export IP_DIR="$ASSETS/ips"
  export ALL_IPS_FILE="$IP_DIR/all"
  export IPS="$IP_DIR/cluster"
  export DHCP_IP_FILE="$IP_DIR/dhcp"
  export NAS_IP_FILE="$IP_DIR/nas"
  export SYSADMIN_IP_FILE="$IP_DIR/sysadmin"

  # Dev purporses
  export DEV_MODE=false
  export TEMP_DIR="$ROOT_DIR/.temp"
  mkdir -p $TEMP_DIR

  # Logging
  export THIS_DEPLOYMENT="$TEMP_DIR/this_deployment"
  export LAST_DEPLOYMENT="$TEMP_DIR/last_deployment"
  export LOG_DIR="$ROOT_DIR/.logs"

  readonly src_dir="$ROOT_DIR/code/src"
}

#-------------------------------------------------------------------------------

# Builds all c files
# in src directory.
# NOTE - This is a temporary
# function until we implement
# some sort of Makefile
build_src() {
  local to_build=$(ls $src_dir)

  mkdir -p bin

  # Compile each file individually
  for filename in $to_build;
  do
    echo "Compiling: $filename"

    # If one file fails, delete all of them. The build is a fail
    if ! gcc -o bin/"${filename%.*}.o" $src_dir/"$filename" -lm; then
      echo "Failed to compile $filename"
      echo "Deleting all src"
      rm -f bin/*
    fi
    echo ""
  done
}

#-------------------------------------------------------------------------------

# TODO - Use Makefile, currently
# just makes sure things are executable
build_sh() {
  # Make sure every script is
  # runnable with ./script_name.sh syntax
  # That way the appropriate shell
  # (bash, sh, expect) is run for a given script

  # TODO - Make sure curl is installed
  # TODO - Make sure sshpass is installed
  # TODO - Might be work packaging the cli.sh
  # with dpkg so we can allow apt-get to
  # manage dependency managment

  sudo apt-get install net-tools gcc curl sshpass -y

  chmod +x **/*.sh
}

#-------------------------------------------------------------------------------

# Builds C and Shell
build() {
  build_src
  build_sh
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

# Just installs the
# docker engine on
# the cluster
install_docker() {
  ./docker/install.sh reinstall_docker
  $UTIL print_success "SUCCESS: " "Docker engine installed"
}

#-------------------------------------------------------------------------------

# Read in the common credentials
# generate the ip list, send the ssh
# keys and install docker on all nodes.
# That way, we are prepared to create the
# docker swarms and install software to them
setup() {
  read_in_common_credentials
  ip_list
  ssh_keys
  install_docker install
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
hostnames() {

  # TODO - Add revert funcionality
  # to revert to original hostname

  echo "Changing each node's hostname"
  ./hostname/install.sh change_hostnames $DHCP_IP_FILE "dns"
  ./hostname/install.sh change_hostnames $NAS_IP_FILE  "nas"
  ./hostname/install.sh change_hostnames $IPS          "gen"
  $UTIL print_success "SUCCESS: " "All hostnames changed"
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

  validate_arg $method
  ./swarm/install.sh $method $DHCP_IP_FILE
  ./swarm/install.sh $method $NAS_IP_FILE
  ./swarm/install.sh $method $IPS
}

#-------------------------------------------------------------------------------

# Open entry point
# pages in the browser
launch_browser() {
  local urls="$@"

  # Open all the links
  $UTIL ignore_exit_status delayed_action 10 "Open_Chrome" launch_browser google-chrome $urls
}

#-------------------------------------------------------------------------------

# Check that all clusters
# are up and running
health_check() {
  local pihole_url="http://$(cat $DHCP_IP_FILE)/admin"
  local nextcloud_url="http://$(head -n 1 $NAS_IP_FILE)"
  local cluster_url="http://$(head -n 1 $IPS):9000/#/auth"

  # Health check on entire system
  $UTIL print_as_list "Performing health check on following servers(s):"  General_Purpose DNS NAS
  $UTIL health_check "DNS" 3 15 $pihole_url
  $UTIL health_check "NAS" 3 30 $nextcloud_url
  $UTIL health_check "GEN" 3 10 $cluster_url

  # We are good to go
  $UTIL print_success "SUCCESS: " "System up and healthy"

  # Show login credentials
  $UTIL display_entry_point "DNS" $pihole_url
  $UTIL display_entry_point "NAS" $nextcloud_url $COMMON_USER
  $UTIL display_entry_point "GEN" $cluster_url   "admin"

  # Open all the tabs
  launch_browser $pihole_url $nextcloud_url $cluster_url
}

#-------------------------------------------------------------------------------

# Make sure all assets
# such as $IPS, $DHCP_IP_FILE,
# are initiaized. We call this
# before any of the install functions
# other than magic is called
check_assets() {
  echo "Checking assets"
}


# Everything above this line will not have an api binding. They are auxiliary
# functions that make the applicaiton work correctly. But, we do not want
# these behaviors exosed.
#===============================================================================

# Install, uninstall
# or reinstall nextcloud
nextcloud() {
  local method=$1

  validate_arg $method
  ./nextcloud/install.sh $method
}

#-------------------------------------------------------------------------------

# Install, uninstall
# or reinstall pihole
pihole() {
  local method=$1

  validate_arg $method
  ./pihole/install.sh $method
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

  validate_arg $method
  ./nat/install.sh $method
}

#-------------------------------------------------------------------------------

# Stands up entire
# environment
magic() {
  setup
  swarms         install_swarm
  hostnames
  nextcloud      install_nextcloud
  samba          install_samba
  pihole         install_pihole
  health_check
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  # Only accept the
  # following functions
  # as the first argument
  case "$1" in
    build)
      build
      ;;

    setup)
      ;;

    magic)
      ;&

    install_docker)
      ;&

    nextcloud)
      ;&

    pihole)
      ;&

    samba)
      ;&

    nat)
      check_assets
      prepare_logs
      "$@"
      ;;

    *)
      $UTIL print_error "FAILURE: " $"Usage: $0 {ip_list|install_docker|nextcloud|pihole|samba|nat}"
      return 1
  esac
}

#-------------------------------------------------------------------------------

main "$@"

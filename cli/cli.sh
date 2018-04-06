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
  export PXE_IP_FILE="$IP_DIR/pxe"
  export SSH_IP_FILE="$IP_DIR/ssh"
  export SYSADMIN_IP_FILE="$IP_DIR/sysadmin"

  # Dev purporses
  export DEV_MODE=false
  export TEMP_DIR="$ROOT_DIR/.temp"
  mkdir -p $TEMP_DIR

  # Logging
  export THIS_DEPLOYMENT="$TEMP_DIR/this_deployment"
  export LAST_DEPLOYMENT="$TEMP_DIR/last_deployment"
  export LOG_DIR="$ROOT_DIR/.logs"

  # Utility environment variables
  export DEFAULT_COMMAND_TIMEOUT="5m"

  # Environment variables for detecting
  # all the VMs that should be part of cluster
  export MINIMUM_NUM_IPS=5
  export EXPECTED_NUM_IPS=6

  # Setting and validating global credentials
  readonly credentials_dir="$ASSETS/credentials"
  readonly hostname_file="$credentials_dir/hostname"
  readonly user_file="$credentials_dir/user"
  readonly password_file="$credentials_dir/password"
}

#-------------------------------------------------------------------------------

# Builds all C files
# in src directory.
# NOTE - This is a temporary
# function until we implement
# some sort of Makefile
build_src() {
  # Directory to C code
  local src_dir="$ROOT_DIR/code/src"
  local to_build=$(ls $src_dir)

  # For the binaries
  mkdir -p bin

  # Compile each file individually
  for filename in $to_build;
  do
    echo "Compiling: $filename"

    # If one file fails, delete all of them. The build is a fail
    if ! gcc -o $BIN/"${filename%.*}.o" $src_dir/"$filename" -lm; then
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
  # TODO - Might be worth packaging the cli.sh
  # with dpkg so we can allow apt-get to
  # manage dependency managment

  sudo apt-get install net-tools gcc curl sshpass -y

  chmod +x **/*.sh
}

#-------------------------------------------------------------------------------

# Reads in common credentials
# such as user and password
read_in_common_credentials() {

  # Read them in from the files
  local host="$(cat $hostname_file)"
  local user="$(cat $user_file)"
  local pass="$(cat $password_file)"

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


  # TODO - Perhaps check a flag for if we want to generate
  # the list or if we want to read in a preexisting list.
  # If we read in a list, then we still need to verify the
  # integrity (validity of ips) of the list

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
  ./docker/install.sh install_docker
  $UTIL print_success "SUCCESS: " "Docker engine installed"
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
  ./hostname/install.sh change_hostnames $SSH_IP_FILE  "ssh"
  ./hostname/install.sh change_hostnames $PXE_IP_FILE  "pxe"
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
  if [[ $method != install* ]]   && \
     [[ $method != reinstall* ]] && \
     [[ $method != uninstall* ]]; then

       $UTIL print_error "FAILURE: " "Only methods 'install*', 'uninstall*' , 'reinstall*' supported"
       return 1
  fi
}

#-------------------------------------------------------------------------------

swarms() {
  local method=$1

  # TODO - if uninstall, disband swarm

  validate_arg       $method
  ./swarm/install.sh $method $DHCP_IP_FILE
  ./swarm/install.sh $method $PXE_IP_FILE
  ./swarm/install.sh $method $SSH_IP_FILE
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
  local pxe_url="http://$(head -n 1 $PXE_IP_FILE):9000/#/auth"
  local ssh_url="http://$(head -n 1 $SSH_IP_FILE):9000/#/auth"
  local cluster_url="http://$(head -n 1 $IPS):9000/#/auth"

  # Health check on entire system
  $UTIL print_as_list "Performing health check on following servers(s):"  General_Purpose DNS PXE SSH NAS
  $UTIL health_check "DNS" 3 15 $pihole_url
  $UTIL health_check "PXE" 3 30 $pxe_url
  $UTIL health_check "SSH" 3 30 $ssh_url
  $UTIL health_check "NAS" 3 30 $nextcloud_url
  $UTIL health_check "GEN" 3 10 $cluster_url

  # We are good to go
  $UTIL print_success "SUCCESS: " "System up and healthy"

  # Show login credentials
  $UTIL display_entry_point "DNS" $pihole_url
  $UTIL display_entry_point "NAS" $nextcloud_url $COMMON_USER
  $UTIL display_entry_point "PXE" $pxe_url       "admin"
  $UTIL display_entry_point "SSH" $ssh_url       "admin"
  $UTIL display_entry_point "GEN" $cluster_url   "admin"

  # Open all the tabs
  launch_browser   \
    $pihole_url    \
    $pxe_url       \
    $ssh_url       \
    $nextcloud_url \
    $cluster_url
}

#-------------------------------------------------------------------------------

# Make sure all assets
# such as $IPS, $DHCP_IP_FILE,
# are initiaized. We call this
# before any of the install functions
# other than magic is called
check_assets() {
  local assets="
  $hostname_file
  $user_file
  $password_file
  $ALL_IPS_FILE
  $DHCP_IP_FILE
  $PXE_IP_FILE
  $SSH_IP_FILE
  $NAS_IP_FILE
  $IPS
  $SYSADMIN_IP_FILE
  "

  echo "Checking that all assets exists"

  if ! $UTIL files_exist $assets; then
    $UTIL print_error "FAILURE: " "All assets do not exist"
    return 1
  fi

  $UTIL print_success "SUCCESS: " "All assets exists"
}


# Everything above this line will not have an api binding. They are auxiliary
# functions that make the applicaiton work correctly. But, we do not want
# these behaviors exposed.
#===============================================================================


# Read in the common credentials
# generate the ip list, send the ssh
# keys and install docker on all nodes.
# That way, we are prepared to create the
# docker swarms and install software to them
setup() {
  prepare_logs
  read_in_common_credentials
  ip_list
  ssh_keys
  install_docker install

  # TODO - Write out to some file
  # that the setup was run. This was
  # other functions that depend on this
  # will only run once they confirm that
  # setup() was already run

  # TODO - Perhaps, also write a function that
  # just SSH into each node to check that docker
  # is installed before any installation functions
  # are run
}

#-------------------------------------------------------------------------------

# Builds C and Shell
build() {
  build_sh
  build_src
}

#-------------------------------------------------------------------------------

# Set the global hostname prefix
set_hostname() {
  local hostname="$1"

  $UTIL valid_hostname $hostname
  echo $hostname > $hostname_file
}

#-------------------------------------------------------------------------------

# Set the global username
set_user() {
  local user="$1"

  $UTIL valid_user $user
  echo $hostname > $user_file
}

#-------------------------------------------------------------------------------

# Set the global password
set_password() {
  local password="$1"

  $UTIL valid_password $password
  echo $hostname > $password_file
}

#-------------------------------------------------------------------------------

# Install, uninstall
# or reinstall nextcloud
nextcloud() {
  local method=$1

  ./nextcloud/install.sh $method
}

#-------------------------------------------------------------------------------

# Install, uninstall
# or reinstall pihole
pihole() {
  local method=$1

  ./pihole/install.sh $method
}

#-------------------------------------------------------------------------------

samba() {
  local method=$1

  ./samba/install.sh $method
}

#-------------------------------------------------------------------------------

# Install, uninstall
# or reinstalls network
# address transation for
# the entire environment
nat() {
  local method=$1

  # ./nat/install.sh $method
}

#-------------------------------------------------------------------------------

openssh() {
  local method=$1
  
  ./openssh/install.sh $method
}

#-------------------------------------------------------------------------------

# Stands up entire
# environment
magic() {

  # TODO - Perhaps check that setup() was run
  # instead of running it in the magic function?

  # TODO - Install a PXE server
  # TODO - Install Open SSH server

  setup
  # swarms         install_swarm
  # hostnames

  openssh        install_openssh
  return 1

  nextcloud      install_nextcloud
  samba          install_samba
  pihole         install_pihole
  health_check
}

#-------------------------------------------------------------------------------

main() {
  local function=$1; shift
  local arg=$1

  # Declare all
  # environment variables
  declare_variables

  # Only accept the
  # following functions
  # as the first argument
  case "$function" in

    # Build all src code
    build)
      ;;

    # Run all setup functions
    setup)
      ;;

    # Set the global password
    set_password)
      ;;

    # Set the global username
    set_user)
      ;;

    # Set the global hostname
    set_hostname)
      ;;

    # Setup and install everything
    magic)

      # Make sure all assets
      # and logs are in place
      # for the next deployment
      check_assets
      prepare_logs
      validate_arg $arg
      ;;

    # Anything else
    # is not accepted
    *)
      $UTIL print_error "FAILURE: " $"Usage: $0 build | setup | magic"
      return 1
  esac

  # Execute the function
  # with it's argument
  $function $arg
}

#-------------------------------------------------------------------------------

main "$@"

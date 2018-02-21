#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Global variables
declare_variables() {
  readonly mac_blacklist=$(cat assets/mac_blacklist)
  readonly mac_whitelist_file="$(pwd)/assets/mac_whitelist"
  readonly ip_whitelist_file="$(pwd)/assets/ip_whitelist"
}

#-------------------------------------------------------------------------------

# Ping each ip in subnet.
# We use this as an auxiliary function
# to enforce arp resolution
ping_subnet() {
  declare -A map_pid_ip
  local subnet=$1
  local ip=""

  # Loop through each
  # ip subnet
  for i in {1..254};
  do
    # Build ip string
    ip=$subnet.$i

    # Ping ips asynchronously
    ping $ip -c 1 -w 5  >/dev/null &

    # Grab the pids
    map_pid_ip[$!]=$ip
  done

  # Await each pid to finish
  for pid in "${!map_pid_ip[@]}";
  do

    # Only echo ips that responded
    if wait $pid; then
      echo "${map_pid_ip[$pid]}"
    fi
  done
}

#-------------------------------------------------------------------------------

add_ip_to_whitelist() {
  local ip=$1;

  # Delete the ip if it's present
  # Add it back to file
  sed -i "/$ip/d" $ip_whitelist_file
  echo $ip >> $ip_whitelist_file
}

#-------------------------------------------------------------------------------

add_mac_to_whitelist() {
  local mac=$1;

  # Delete the ip if it's present
  # Add it back to file
  sed -i "/$mac/d" $mac_whitelist_file
  echo $mac >> $mac_whitelist_file
}

#-------------------------------------------------------------------------------

# Adds an ip to the
# list of whitelisted
# ips and macs
whitelist() {
  local ips=$@
  local mac=""

  for ip in $ips;
  do
    mac=$($UTIL get_mac_from_ip $ip)

    add_ip_to_whitelist $ip

    # NOTE - For VMs with bridge
    # network adapter, this will
    # cause them all to get whitelisted

    # add_mac_to_whitelist $mac
  done
}

#-------------------------------------------------------------------------------

# Provided a list of ips
# print only the ips whose
# MAC addresses begin with
# one of a specified set of prefixes
filter_by_mac() {
  local ips=$@
  local ip=""
  local mac=""

  # Loop through all nodes
  for ip in $ips;
  do

    # Get the mac address
    mac=$($UTIL get_mac_from_ip $ip)

    # TODO - Check whitelisted macs as well
    # Example, if sysadmins ip changed, it will
    # get added to cluster next time around.
    # We don't want this

    # TODO - Check for prexisting whitelisted ips

    # Only echo ips that begin with one of the predefined prefixes
    if [[ $( $UTIL search_list_by_prefix $mac $mac_blacklist ) = true ]]; then
      echo $ip
    fi

  done
}

#-------------------------------------------------------------------------------

# Pop the first ip
# and print the rest
pick_dhcp_server() {
  local dhcp_ip=$1; shift
  local ips=$@

  echo $dhcp_ip > $DHCP_IP_FILE

  # Echo the rest
  for ip in $ips;
  do
    echo $ip
  done
}

#-------------------------------------------------------------------------------

# Pop first N ips
# and print the rest
pick_nas_servers() {

  # TODO - Allow to pick N
  # NAS servers rather than
  # just two

  local nas_1=$1; shift
  local nas_2=$1; shift
  local ips=$@

  # Delete old file, write new
  # one with new ip addresses
  $UTIL recreate_files $NAS_IP_FILE
  echo $nas_1 >> $NAS_IP_FILE
  echo $nas_2 >> $NAS_IP_FILE

  # Echo the rest
  for ip in $ips;
  do
    echo $ip
  done
}

#-------------------------------------------------------------------------------

# Make sure the ip of this
# device does not end up on
# the list of ip addresses
pick_sysadmin() {
  local sysadmin_ip=$( $UTIL my_ip )

  # Delete the ip if it's present
  sed -i "/$sysadmin_ip/d" $SYSADMIN_IP_FILE

  # Add it back to file
  echo $sysadmin_ip >> $SYSADMIN_IP_FILE

  # Loop through all ips
  # If they are not this ip
  for ip in $ips;
  do
    if [[ $ip != $sysadmin_ip ]]; then
      echo $ip
    fi
  done
}

#-------------------------------------------------------------------------------

# Only prints ips that
# are not whitelisted
filter_by_whitelist() {
  local ips=$@
  local whitelist=$(cat $ip_whitelist_file)

  for ip in $ips;
  do

    # Only each if it's not whitelisted
    if [[ $( $UTIL search_list $ip $whitelist) = false ]]; then
      echo $ip
    fi
  done
}

#-------------------------------------------------------------------------------

# Make sure we have ssh access
# to all remaining ips. Filter
# out those that we cannot access.
verify_list() {
  declare -A map_pid_ip
  local ips=$@

  # Loop through each
  # ip subnet
  for ip in $ips;
  do

    # Give it 5 seconds to establish an ssh connection, otherwise error out
    (timeout 5 $UTIL my_sshpass $COMMON_USER@$ip ssh echo "Test" > /dev/null 2>&1 ) &

    map_pid_ip[$!]=$ip
  done

  # Await each pid to finish
  for pid in "${!map_pid_ip[@]}";
  do

    # Only echo ips that we
    # successfully connected to
    if wait $pid; then
      echo "${map_pid_ip[$pid]}"
    fi
  done

}

#-------------------------------------------------------------------------------

# Create a global list
# by concatenating all of
# them and removing white space
# in case any of the files are empty
create_full_list() {
  $UTIL recreate_files $ALL_IPS_FILE

  # Concat all server's ips
  cat $DHCP_IP_FILE >> $ALL_IPS_FILE
  cat $NAS_IP_FILE  >> $ALL_IPS_FILE
  cat $IPS          >> $ALL_IPS_FILE

  # Remove whitespace if
  # if any was added from
  # cat empty files
  sed -i '/^\s*$/d' $ALL_IPS_FILE
}

#-------------------------------------------------------------------------------

# Create the lists of ip
# addresses applying the
# right filters to only get
# the right ip addresses
generate_list() {
  local ips=""
  local subnet=""

  # Build the lists
  subnet=$( $UTIL my_subnet         );  # Figure out what subnet we are on
  ips=$(    ping_subnet      $subnet);  # Ping all ips on subnet, recording those that respond
  ips=$(    filter_by_mac       $ips);  # Filter out ips whose mac don't match our filter
  ips=$(    filter_by_whitelist $ips);  # Filter out any other ips that we have whitelisted
  ips=$(    pick_sysadmin       $ips);  # Strip off the ip off of the device running this script

  # Make sure we have
  # at least 1 ip left
  if [[ $ips = "" ]]; then
    $UTIL print_error "ERROR: " "No valid ip(s) resolved, at least 1 required"
    return 1
  fi

  ips=$(    verify_list         $ips);  # Ensure we have ssh access to all other devices
  ips=$(    $UTIL sort_ips      $ips);  # Sort in ascending order
  ips=$(    pick_dhcp_server    $ips);  # Pick first ip in list as dhcp server
  ips=$(    pick_nas_servers    $ips);  # Pick next N servers as network attached storages
  echo "$ips" > $IPS                 ;  # The remaining ip(s) will be considered general purpose servers
  create_full_list                   ;  # Create a global list of ip addresses for all servers on network

  # Display the lists by category
  $UTIL print_as_list "DHCP Server:"       $(cat $DHCP_IP_FILE)
  $UTIL print_as_list "NAS Server(s):"     $(cat $NAS_IP_FILE)
  $UTIL print_as_list "System Admin(s):"   $(cat $SYSADMIN_IP_FILE)
  $UTIL print_as_list "Cluster Server(s):" $(cat $IPS)
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

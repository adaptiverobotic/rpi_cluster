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

    # Echo ips that responded
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

    # Echo only ips that begin with one of the predefined prefixes
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

  for ip in $ips;
  do
    echo $ip
  done
}

#-------------------------------------------------------------------------------

# Pop first 2 ips
# and print the rest
pick_nas_servers() {
  local nas_1=$1; shift
  local nas_2=$1; shift
  local ips=$@

  # Delete old file, write new one
  # with new ip addresses
  echo $nas_1 > $NAS_IP_FILE
  echo $nas_2 >> $NAS_IP_FILE

  # Print the rest
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
  local sysadmin_ip=$( $UTIL my_ip)

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

# Verifies that we actually
# have ssh access to the list
# of ips that we constructed.
# ips that reject the connection,
# or the username doesn't work for, etc,
# will be removed from the list.
# We also have an optional whitelist
# of ips that even if they meet
# the criteria, they will be removed.
# Haha, see what I did there. Whitelist...
# I'm black, q tu quieres q yo te diga...
verify_list() {
  declare -A map_pid_ip
  local ips=$@

  # Loop through each
  # ip subnet
  for ip in $ips;
  do

    # Give it 5 seconds to establish an ssh connection
    (timeout 5 $UTIL my_sshpass $COMMON_USER@$ip ssh echo "Test" > /dev/null 2>&1 ) &

    map_pid_ip[$!]=$ip
  done

  # Await each pid to finish
  for pid in "${!map_pid_ip[@]}";
  do

    # Echo ips that we
    # successfully connected to
    if wait $pid; then
      echo "${map_pid_ip[$pid]}"
    fi
  done

}

#-------------------------------------------------------------------------------

generate_list() {
  local ips=""
  local subnet=""

  # Build the lists
  subnet=$( $UTIL my_subnet         );  # Figure out what subnet we are on
  ips=$(    ping_subnet      $subnet);  # Ping all ips on it, recording those that respond
  ips=$(    filter_by_mac       $ips);  # Filter out ips whose macs do not match our filter
  ips=$(    filter_by_whitelist $ips);  # Filter out any other ips that we have whitelisted
  ips=$(    pick_sysadmin       $ips);  # Strip off the ip off of the device running this script
  ips=$(    verify_list         $ips);  # Ensure we have ssh access to all other devices
  ips=$(    $UTIL sort_ips      $ips);  # Sort in ascending order
  ips=$(    pick_dhcp_server    $ips);  # Pick first ip in list as dhcp server
  ips=$(    pick_nas_servers    $ips);  # Pick next N sevrers as network attached storages
  echo "$ips" > $IPS                 ;  # The remaining ips will be considered servers

  # Display the lists
  $UTIL print_as_list "DHCP Server:" $(cat $DHCP_IP_FILE)
  $UTIL print_as_list "NAS Servers:" $(cat $NAS_IP_FILE)
  $UTIL print_as_list "Sysadmins:"   $(cat $SYSADMIN_IP_FILE)
  $UTIL print_as_list "Cluster:"     $(cat $IPS)
}

#-------------------------------------------------------------------------------

main() {
  declare_variables


  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

# exit 1

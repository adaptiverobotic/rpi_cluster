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

  # Delete and recreate them to get a fresh start
  $UTIL recreate_files $mac_whitelist_file $ip_whitelist_file
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

  # Whitelist them
  whitelist $nas_1 $nas_2

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

  # Whitelist it
  whitelist $sysadmin_ip

  for ip in $ips;
  do
    if [[ $ip != $sysadmin_ip ]] && [[ $ip != "192.168.2.252" ]]; then
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
  local ips=$@
  local temp_ips_file="$TEMP_DIR/temp_ips"

  # recreate
  rm -f $temp_ips_file
  touch $temp_ips_file

  # Write out  to file
  for ip in $ips;
  do
    echo $ip >> $temp_ips_file
  done

  # TODO - perhaps to try ssh in
  # without erroring out, and only
  # storing ips we succeeded with. We will manually
  # do that with my_sshpass instead of using
  # a function that calls our loop nodes function

  echo "Checking that all resolved ips can be reached via ssh"
  $UTIL valid_ip_list $temp_ips_file
  $UTIL print_success "SUCCESS: " "All ips are reachable"
}

#-------------------------------------------------------------------------------

# 1.  Figure out the subnet
# 2.  Ping the whole subnet
# 3.  Capture ips that responded
# 4.  Get their mac addresses
# 5.  Filter out ips with invalid macs
# 6.  Sort the ips
# 7.  Select DHCP server, whitelist it's ip
# 8.  Select the NAS server, whitelist, it's ip
# 9.  Whitelist this (sysadmin) device's ip
# 10. Filter out all whitelisted ips
# 11. Return remaining ips
main() {
  local ips=""
  local subnet=""

  declare_variables
  subnet=$( $UTIL my_subnet         )
  ips=$(    ping_subnet      $subnet)
  ips=$(    pick_sysadmin       $ips)
  ips=$(    filter_by_mac       $ips)

  # This function builds whitelist
  # of ips that matches by mac but
  # we don't have access to
  verify_list $ips

  # Remove the bad ones
  ips=$(    filter_by_whitelist $ips)

  # From here on, we should have ssh
  # access to all nodes that were listed
  ips=$(    $UTIL sort_ips      $ips)
  ips=$(    pick_dhcp_server    $ips)
  ips=$(    pick_nas_servers    $ips)


  # The rest are cluster workers
  echo "$ips" > $IPS

  # Display cluster info
  $UTIL print_as_list "DHCP Server:" $(cat $DHCP_IP_FILE)
  $UTIL print_as_list "NAS Servers:" $(cat $NAS_IP_FILE)
  $UTIL print_as_list "Sysadmins:"   $(cat $SYSADMIN_IP_FILE)
  $UTIL print_as_list "Cluster:"     $(cat $IPS)

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

# exit 1

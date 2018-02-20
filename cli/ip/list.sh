#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Global variables
declare_variables() {
  # NOTE - Placeholder for if
  # we need to declare globals
  readonly whitelist=$(cat assets/whitelist)

  # TODO - Perhaps read in files DHCP and NAS and sysadmin
}

#-------------------------------------------------------------------------------

# Prints subnet of
# this machine to console
echo_subnet() {
  local ip=$( $UTIL my_ip)
  echo ${ip%.*}
}

#-------------------------------------------------------------------------------

# Ping each ip in subnet.
# We use this as an auxiliary function
# to enforce arp resolution
ping_subnet() {
  declare -A map_pid_ip
  local subnet=$1
  local ip=""

  # Ping entire subnet
  for i in {1..254};
  do
    ip=$subnet.$i
    ping $ip -c 1 -w 5  >/dev/null &

    # Grab the pids of
    # each background
    # process
    map_pid_ip[$!]=$ip
  done

  # Await each pid to finish
  for pid in "${!map_pid_ip[@]}";
  do

    # If an ip responded,
    # exit status is 0
    if wait $pid; then
      echo "${map_pid_ip[$pid]}"

    # Otherwise, it's
    # not reachable
    else
      :
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
  # TODO - Abstract this to list.sh
  $UTIL valid_ip_list $IPS
  $UTIL print_success "SUCCESS: " "All common credentials are valid"
}

#-------------------------------------------------------------------------------

# Print final list
# to console
display_list() {
  $UTIL print_as_list "List of ips:" $(cat $IPS)
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
  local filters=$(cat assets/filters)

  # Loop through all nodes
  for ip in $ips;
  do

    # Get the mac address
    mac=$(arp -an $ip \
        | awk '{print $4}' \
        | tr -d '()')

    # Match by prefix
    if [[ $( $UTIL search_list_by_prefix $mac $filters ) = true ]]; then
      echo $ip
    fi

  done
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
  subnet=$(echo_subnet)
  ips=$(ping_subnet $subnet)
  ips=$(filter_by_mac $ips)
  ips=$( $UTIL sort_ips $ips )

  echo "$ips"

  echo "$ips" > $IPS

  verify_list
  # display_list

  # Placeholder for if we
  # want to accept command
  # line arguments
  # "$@"
}

#-------------------------------------------------------------------------------

main "$@"

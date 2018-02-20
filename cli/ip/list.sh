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

# NOTE - Figure out our subnet
# dynamically
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

# Get this device's ip and mac, as it
# is not going to be returned by the ARP broadcast.
# We must manually append it to the list

# NOTE - Perhaps ping the entire subnet
# so that the ips come up by time we run arp -a
# It appears as though they won't show up
# for a fresh install unless we ping each ip
# that we expect to join. This is not practical

check_this_device() {
  # NOTE - Get output form ifconfig
  # for eth0 interface. We use this
  # as it is the only interface that
  # we can gaurantee will come back
  # as a Raspberry Pi Foundation MAC address.
  # For now, we will place the constraint
  # that the device running this install
  # script is a Raspberry Pi. The rest
  # of the nodes' MAC addresses more free as
  # they are constrained by all of the MAC prefixes
  # that are listed in the file assets/filters.
  # We do this, so that we are not adding other
  # devices such as development machines or phones
  # that are connected to the network, but
  # are not going to be part of the cluster.
  interface="eth0"
  temp=($(ifconfig $interface | grep -w inet))

  # Store ip and mac
  this_ip=${temp[1]}
  this_mac="$(cat /sys/class/net/$interface/address)"

  # Append this device's info to list
  ip_macs+=(";$this_ip;$this_mac")
}

#-------------------------------------------------------------------------------

# Build the list of ip addresses
# that have a corresponding mac address
# that meets a given criteria. The
# criteria is specified by a file called
# filters that containers a list of mac address
# prefixes. If an ip address on the subnet begins
# with at least one of the prefixes, it is
# added to the list.
generate_list() {
  local filters="assets/filters"

  echo "Creating list of ip addresses"

  # Delete old ip address list
  rm -f $IPS

  # Create new empty list file
  touch $IPS

  # TODO - Let's just do this manually so
  # what the code is actually doing. But save
  # it because its a nice regex. Just too complicated
  # and not condusive to readability
  # Read in all device on network info as single string in ; delimited list in format hostname;ip_address;mac_address
  temp=$(arp -a | sed 's/^\([^ ][^ ]*\) (\([0-9][0-9.]*[0-9]\)) at \([a-fA-F0-9:]*\)[^a-fA-F0-9:].*$/\1;\2;\3/')

  # Convert list to array
  ip_macs=($temp)

  # NOTE - Will fail on device without
  # eth0 network interface (laptops). We
  # Would only run this if we are initializing
  # the cluster from a Raspberry Pi, or whatever
  # the common hardware is for the cluster.

  # check_this_device

  # Loop through array of hostname;ip;mac mappings
  for i in "${ip_macs[@]}"
  do
    # Boolean flag that we use
    # to decide whether or not to
    # add an ip to list of ips
    valid=false

    # Separate ip and mac into separate variables
    # TODO - Possibly shorten??
    while IFS=';' read -ra ADDR; do
      ip=${ADDR[1]}
      mac=${ADDR[2]}
    done <<< "$i"

    # Check that $mac matches at least
    # one of the filters specified
    # in the assets/filter file
    while read line; do

      # If $mac address begins with the
      # mac address prefix specified by $line,
      # then $mac is a valid address. Example:
      # if $mac=12:34, and $line=12, then $mac is valid
      if [[ $mac == $(echo $line)* ]]; then
        valid=true
        break
      fi
    done <$filters

    # Don't add whitelisted ips
    if [[ $($UTIL search_list $ip $whitelist) == "true" ]]; then
      $UTIL print_error "FAILURE: " "ip address $ip is whitelisted, not adding"
      valid=false
    fi

    # If the current $mac is valid,
    # write its corresponding ip
    # out to the ip_address file
    if [[ $valid == true ]]; then
      $UTIL print_success "SUCCESS: " "Adding ip address $ip to list"
      echo $ip >> $IPS
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

filter_by_mac() {
  local ips=$@

  for ip in $ips;
  do
    echo $ip
  done
}

#-------------------------------------------------------------------------------

# Adds own mac address to the
# whitelist of mac addresses
# not to add even if the hardware
# and credentials are appropriate
# TODO - Remember to add ALL mac
# addresses for all interfaces. That
# way this machine does not accidently
# end up in the list and we can also
# do sysadmin stuff from similar hardware
# instead of having a whole laptop
# for this. That way we have ONE entry
# point to our cluster.
whitelist_self() {
  echo ""
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

  generate_list
  verify_list
  display_list

  # Placeholder for if we
  # want to accept command
  # line arguments
  # "$@"
}

#-------------------------------------------------------------------------------

main "$@"

#!/bin/bash
set -e

#----------------------------------------------------------------------------------------

# Echos the last 3 digits
# of this device's IPv4 ip address
echo_my_ip() {
  # Is there a cleaner way?
  local tmp0=$(hostname -I)
  local tmp1=($tmp0)
  local ip=${tmp1[0]}
  local num=$(echo $ip | cut -d . -f 4)

  echo $num
}

#----------------------------------------------------------------------------------------

# Set global values
declare_variables() {
  local user=$1
  readonly hostname=$user-$(echo_my_ip)
}

#----------------------------------------------------------------------------------------

# Sets temporary hostname so we do
# not need to reboot or restart for
# our changes to be persisted. NOTE - the
# next time we reboot, we will advertise our
# hostname as the value that we read in from
# /etc/hostname. So we must make sure that
# We are setting our temporary hostname to
# the same thing as the value we write to out
# new /etc/hostname. Otherwise, we will join
# swarms, etc under one hostname, and when we
# reboot those names will be different. This
# does not appear to affect docker swarm performance,
# etc because they talk by ip address. However,
# we will have a different set of hostnames for
# swarm administration than our actual hostnames
# that we may use for easy manual ssh, etc.
set_temp_hostname() {
  echo "Setting temporary hostname to: $hostname"
  hostnamectl set-hostname $hostname
  echo "Succesfully set temporary hostname to: $hostname"
}

#----------------------------------------------------------------------------------------

# Changes hostname in /etc/hostname
change_hostname() {
  local etc_hostname="/etc/hostname"

  echo "Changing hostname in: $etc_hostname"
  echo "Old hostname in $etc_hostname: $(cat $etc_hostname)"

  # Change hostname in hostname /etc/hostname
  # TODO - Backup old /etc/hostname
  sudo rm -f $etc_hostname
  sudo touch $etc_hostname
  echo $hostname >> $etc_hostname

  echo "New Hostname in $etc_hostname: $(cat $etc_hostname)"
}

#----------------------------------------------------------------------------------------

# Change hostname in /etc/hosts
change_host() {
  local hosts="/etc/hosts"

  # Change host name in /etc/hosts
  # TODO - Backup old /etc/hosts
  cp $hosts $hosts.temp
  sed '$ d' $hosts.temp > $hosts
  rm -f $hosts.temp
  echo "127.0.1.1       $hostname" >> $hosts
}

#----------------------------------------------------------------------------------------

main() {
  declare_variables "$@"
  set_temp_hostname
  change_hostname
  change_host
}

#----------------------------------------------------------------------------------------

main "$@"

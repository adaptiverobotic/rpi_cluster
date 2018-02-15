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

declare_variables() {
  local user=$1
  readonly hostname=$user-$(echo_my_ip)
}

#----------------------------------------------------------------------------------------

# Changes hostname in /etc/hostname
change_hostname() {
  local etc_hostname="/etc/hostname"

  # We want the advertised hostname to take effect
  # immediately because if we are inserting nodes
  # into a cluster such as docker swarm, the hostname
  # from /etc/hostname will be used. However, the changes
  # will not take effect until the device reboots. So,
  # currently, the default hostname is used.
  # TODO - see https://askubuntu.com/questions/87665/how-do-i-change-the-hostname-without-a-restart/516898

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
  change_hostname
  change_host
}

#----------------------------------------------------------------------------------------

main "$@"

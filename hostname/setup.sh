#!/bin/bash
set -e

# hostname
etc_hostname="/etc/hostname"
hosts="/etc/hosts"

# For creating host
user=$1

# We want the advertised hostname to take effect
# immediately because if we are inserting nodes
# into a cluster such as docker swarm, the hostname
# from /etc/hostname will be used. However, the changes
# will not take effect until the device reboots. So,
# currently, the default hostname is used.
# TODO - see https://askubuntu.com/questions/87665/how-do-i-change-the-hostname-without-a-restart/516898

# Get this node's IP from
# info about it's current
# ssh connection
# TODO - Abstract this to util.sh
tmp0=$(hostname -I)
tmp1=($tmp0)
ip=${tmp1[0]}

# Get last 3 digits from ip
# TODO - Abstract this to util.sh
num=$(echo $ip | cut -d . -f 4)

# if ip=192.168.2.100
# if user=pi
# hostname=pi-100
hostname=$user-$num

echo "Setting up $hostname"

# Change hostname in hostname /etc/hostname
# TODO - Backup old /etc/hostname
sudo rm -f $etc_hostname
sudo touch $etc_hostname
echo $hostname >> $etc_hostname

echo "Changed hostname in /etc/hostname to $hostname"

# Change host name in /etc/hosts
# TODO - Backup old /etc/hosts
cp $hosts $hosts.temp
sed '$ d' $hosts.temp > $hosts
rm -f $hosts.temp
echo "127.0.1.1       $hostname" >> $hosts

echo "Changed hostname in /etc/hosts to $hostname"
echo "Hostname: $(cat /etc/hostname)"

#!/bin/bash
set -e

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get common login credentials
user=$(cat ${DIR}/../assets/user)
password_file="${DIR}/../assets/password"
ips="${DIR}/../assets/ips"

# Specify ssh parameters
ssh_args="
-o ConnectTimeout=5 \
-o IdentitiesOnly=yes \
-o userknownhostsfile=/dev/null \
-o stricthostkeychecking=no"

# SSH into a node
# using global ssh settings
my_ssh() {

  # Format: user@ip
  user_ip=$1

  # SSH into a given node passing the password from a file
  ssh $ssh_args -n $user_ip ${@:2}
}

# SCP into a node
# using global ssh settings
my_scp() {

  # Format: user@ip
  user_ip=$1

  # SCP a file to a given node passing the password from a file
  scp $ssh_args -r "${@:2}" $user_ip:
}

# SSH or SCP into a node
# using global ssh settings,
# in addition, provide a password
# that is read in from a file.
# Use this to automate SSH / SCP before
# ssh keys are generated and copied to each node.
my_sshpass() {

  # Format: ssh
  # will map to functions such
  # as my_ssh, my_scp
  protocol=$1

  sshpass -f $password_file my_$protocol $@
}

# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {

  # File to read ips from
  file=$1

  # Command to run
  action=$2

  while read ip; do
    echo "Action: $action: $user@$ip"

    # If we want to SSH
    if [[ $action == "ssh" ]]; then

      my_ssh $user@$ip "${@:3}"

    # If we want to SCP
    elif [[ $action == "scp" ]]; then

      my_scp $user@$ip "${@:3}"
    fi
  done <$file
}

# SSH into a list of node specified
# by a file ($1), and execute all the
# commands that follow
ssh_specific_nodes() {

  # Send file list first
  loop_nodes $1 ssh ${@:2}
}

# Provided a list of node ips
# ($1) and a list of files
# (remaning arguments), SCP the files
# to each node ip in the list.
scp_specific_nodes() {

  # Send file list first
  loop_nodes $1 scp ${@:2}
}

# Execute a command on each
# node that is specified in
# the global list of ips
ssh_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $ips ssh "$@"
}

# SCP a set of files to each
# node that is specified in
# the global list of ips
scp_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $ips scp "$@"
}

# Power off and power
# on each node.
reboot_nodes() {

  # Power off and reboot
  # each node in cluster
  ssh_nodes reboot -p
}

# Determine whether or
# not a command is is
# installed on a device
is_installed() {

  # Determines whether or
  # not a command is installed
  echo "0"
}

# Print this device's
# ip address to stdout
my_ip() {

  # NO, specific to linux
  tmp0=$(hostname -I)
  tmp1=($tmp0)
  i=${tmp1[0]}
  echo $i
}

"$@"

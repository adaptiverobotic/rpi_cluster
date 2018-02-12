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
-o LogLevel=error \
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

# SCP a list of files from
# a remote server to this device
# TODO - Expand to support
# multiple files
my_scp_get_file() {
  # Format: user@ip
  user_ip=$1
  local_dir=$2

  args=${@:3}

  # Make the local_dir
  # if it does not exist
  mkdir -p $local_dir

  # SCP a file to a given node passing the password from a file
  scp $ssh_args -r $user_ip:\"$args\" $local_dir
}

# SSH or SCP into a node
# using global ssh settings.
# In addition, provide a password
# that is read in from a file.
# Use this to automate SSH / SCP before
# ssh keys are generated and copied to each node.
my_sshpass() {

  # Format: ssh
  # will map to functions such
  # as my_ssh, my_scp
  protocol=$1

  # Format: user@ip
  user_ip=$2

  # If we want to SSH and execute commands on a node
  if [[ $protocol == "ssh" ]]; then

    call="$protocol $ssh_args -n $user_ip ${@:3}"

  # If we want to SCP a file to a node
  elif [[ $protocol == "scp" ]]; then

    call="$protocol $ssh_args -r "${@:3}" $user_ip:"

  # We want to copy a public key toa node
  elif [[ $protocol == "ssh-copy-id" ]]; then
    call="$protocol $ssh_args ${@:3} $user_ip"

  else
    echo "$protocol not supported"
  fi

  # Make SSH or SCP call passing the password
  # in from a file to automate the process
  sshpass -f $password_file $call
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

clean_workspace() {
  echo "Clearing home directory"

  echo "rm -vrf ~/*" >> clean_home_dir.sh
  chmod 777 clean_home_dir.sh

  # Clean the home directory of non-hidden files
  scp_specific_nodes $1 clean_home_dir.sh
  ssh_specific_nodes $1 ./clean_home_dir.sh

  # Delete local file
  rm -f clean_home_dir.sh
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

# Executes a command after N seconds
delayed_action() {
  delay=$1
  message=$2
  action=${@:3}

  secs=$(( 30 ))
  while [ $secs -gt 0 ]; do
     echo -ne "$message: $secs\033[0K\r"
     sleep 1
     : $((secs--))
  done

  $action
}

"$@"

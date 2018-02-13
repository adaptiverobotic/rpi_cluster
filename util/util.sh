#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"


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
  ssh $ssh_args -f $user_ip ${@:2}
}

# SCP into a node
# using global ssh settings
my_scp() {

  # Format: user@ip
  user_ip=$1

  # SCP files from local to remote
  scp $ssh_args -r ${@:2} $user_ip:
}

# SCP a list of files from
# a remote server to this device
# TODO - Expand to support
# multiple files
my_scp_get_file() {
  # Format: user@ip
  user_ip=$1

  # Directory to write to
  local_dir=$2

  # Files to download
  args=${@:3}

  # Make the local_dir
  # if it does not exist
  mkdir -p $local_dir

  # SCP the files from remove to local
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
  sshpass -p $COMMON_PASS $call
}

num_lines() {
  cat $1 | wc -l
}

# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {

  # TODO - See: https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0

  # The script at this point works. But, it takes a lot of time.
  # Most of the nodes during the setup process are waiting
  # because we are doing ssh or scp in sequence. We should
  # kick off each process on a different thread / subprocess
  # and just wait for all of them them to finish. NOTE - By
  # default, simply kicking a process off to the background
  # will pipe its output to /dev/null as well as it exit with
  # status 0. Essentially, & does not care if the command was executed
  # successfully or not. In order for us to make sure out install
  # process is going smoothly, we should keep track of the process
  # id, and await their completions as a group. If all of them
  # come back 0, then this function will return 0. If any fail
  # then the entire function fails. NOTE - We also now want to start
  # logging the output of each subprocess into a file. Overall,
  # if implemented correctly, we should get a similar behavior,
  # but the length of the install process will be roughly the same,
  # independent of how many nodes we have. Currently T(n) = n

  # File to read ips from
  file=$1

  # Command to run
  action=$2

  echo "Checking that $file exists"
  if ! ls $file > /dev/null; then
    echo "File: $file Could not be found"
    return 1
  fi

  # Get number of lines in file
  temp=$(num_lines $file)
  number_of_lines=$(( $temp ))

  # Make sure there is at least one line
  if [[ number_of_lines < 1 ]]; then
    echo "File: $file Must have at least one line"
    return 1
  fi

  pids=""
  result=0

  while read ip; do
    echo "$action: $COMMON_USER@$ip"

    # my_ssh, my_scp, send it off to background
    (my_$action $COMMON_USER@$ip ${@:3}) &

    # Keep a list of process ids
    pids="$pids $!"
  done <$file

  # Loop through pids and wait
  # for them to complete.
  for pid in $pids; do
    wait $pid || let "result=1"
  done

  return $result
}

# SSH into a list of node specified
# by a file ($1), and execute all the
# commands that follow
ssh_specific_nodes() {
  ip_list=$1
  args=${@:2}

  # Send file list first
  loop_nodes $ip_list ssh $args
}

# Provided a list of node ips
# ($1) and a list of files
# (remaning arguments), SCP the files
# to each node ip in the list.
scp_specific_nodes() {
  ip_list=$1
  args=${@:2}

  # Send file list first
  loop_nodes $ip_list scp $args
}

# Execute a command on each
# node that is specified in
# the global list of ips
ssh_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $IPS ssh $@
}

# SCP a set of files to each
# node that is specified in
# the global list of ips
scp_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $IPS scp $@
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
  # TODO - Need to ignore error when ssh is closed
  ssh_nodes echo "rebooting"; (sleep 1 && sudo reboot &) && exit
}

# Determine whether or
# not a command is is
# installed on a device
is_installed() {

  # Call the command
  if $1; then
    return 0
  else
    return 1
  fi
}

# Print this device's
# ip address to stdout
my_ip() {

  # Specific to linux. will faill on Mac
  echo $(hostname -I | awk '{print $1}')
}

# Executes a command after N seconds
delayed_action() {
  delay=$1

  # Get everything between quotes
  message=$2

  # TODO - Allow for spaces in arguments
  # so that we can have a real message
  action=${@:3}

  secs=$(( $delay ))
  while [ $secs -gt 0 ]; do
     echo -ne "$message: $secs\033[0K\r"
     sleep 1
     : $((secs--))
  done

  # Skip a line
  echo ""

  # Execute the action
  $action
}


$@

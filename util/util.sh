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
  ssh $ssh_args -n $user_ip ${@:2}
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

  # Format: user@ip
  user_ip=$1

  # Format: ssh
  # will map to functions such
  # as my_ssh, my_scp
  protocol=$2

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
    return 1
  fi

  # Make SSH or SCP call passing the password
  # in from a file to automate the process
  sshpass -p $COMMON_PASS $call
}

num_lines() {

  # Counts the number of lines in
  # a file, ignore new line / empty strings
  cat $1 | sed '/^\s*$/d' | wc -l
}

# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {

  # TODO - See: https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0

  # File to read ips from
  file=$1

  # Command to run
  action=$2

  # If we want to run loop
  # synchronously or async
  # TODO - Allow this to be
  # sent as a flag
  async=1

  # Make sure the file exists
  if ! ls $file > /dev/null; then
    echo "File: $file Could not be found"
    return 1
  fi

  pids=""
  result=0

  while read ip; do
    echo "$action: $COMMON_USER@$ip"

    # Run in async mode. Essentially
    # kick off each subprocess and send
    # it to the background.
    if [[ $async -eq 0 ]]; then
      # 1. We are mapping ssh to my_ssh, scp -> my_scp and so on
      # 2. We are running an inner subprocess that will pipe stout
      # and stderr to a file
      # 3. This is all encapsulated in another subprocess that we throw into
      # the background. The outer most process' pid will be captured
      # and stored into an array. We can then await these processes as a group
      ( ( $action $COMMON_USER@$ip ${@:3}) >> $LOG_DIR/$ip.log 2>&1 ) &

      # Keep a list of process ids
      pids="$pids $!"

    # Run synchronously. Wait for
    # each action to complete before
    # going onto the next action.
    else

      # Kick off sub process, logging its output to a file while
      # still making it present on the console.
      ( ( $action $COMMON_USER@$ip ${@:3} ) 2>&1 | tee -a $LOG_DIR/$ip.log )
    fi
  done <$file

  # Await subprocess completion
  # if we are running in async mode
  if [[ $async -eq 0 ]]; then
    echo "Waiting for all processe(s) finish:"
    printf '%s\n' "${pids[@]}"

    # Loop through pids and wait
    # for them to complete.
    for pid in $pids; do
      wait $pid || let "result=1"
    done

    # Check exit status
    if [[ $result -ne 0 ]]; then
      echo "FAILURE - At least process exited with a non-zero status"
    fi
  fi

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
  loop_nodes $ip_list my_scp $args
}

# Execute a command on each
# node that is specified in
# the global list of ips
ssh_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $IPS my_ssh $@
}

# SCP a set of files to each
# node that is specified in
# the global list of ips
scp_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $IPS my_scp $@
}

sshpass_nodes() {

  loop_nodes $IPS my_sshpass $@
}

sshpass_specific_nodes() {

  loop_nodes $1 my_sshpass ${@:2}
}

clean_workspace() {
  echo "Clearing remote working directory"

  echo "rm -rf ~/*" >> clean_home_dir.sh
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

timed_action() {
  START_TIME=$SECONDS

  "$@"

  ELAPSED_TIME=$(($SECONDS - $START_TIME))

  echo "Completed $1 deployment in: $ELAPSED_TIME second(s)"
}

"$@"

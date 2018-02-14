#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

declare_variables() {
  general_ssh_args="$(cat assets/ssh_args_file)"

  ssh_args="$general_ssh_args"
  scp_args="$general_ssh_args -r"
}

#-------------------------------------------------------------------------------

# SSH into a node and
# execute a command
my_ssh() {
  local user_ip=$1; shift
  local args=$@

  # TODO - Figure out why -n does not work when we
  # copy the ssh-id. it prints the key on screen.
  # unacceptable.
  # SSH into a given node passing the password from a file
  ssh $ssh_args -n $user_ip "$args"
}

#-------------------------------------------------------------------------------

# SCP some files
# to a node
my_scp() {

  # Format: user@ip
  local user_ip=$1; shift
  local args=$@

  scp $scp_args $args $user_ip:
}

#-------------------------------------------------------------------------------

# Retrieve files from a node
# and download to a specified
# local directory. NOTE - This is not
# compatible with the loop nodes function.
# Even if it were, it would not serve us
# because the file will get overriden
# locally as the loopp_nodes() functions
# provides no facility to change / append
# a unique identifier to to the local directory.
my_scp_get() {

  # Format: user@ip
  local ip=$1; shift
  local local_dir=$1; shift
  local args="$@"

  # Make the local_dir
  # if it does not exist
  mkdir -p $local_dir

  for file in $args; do
    scp $scp_args $COMMON_USER@$ip:$file $local_dir
  done
}

#-------------------------------------------------------------------------------

# SSH or SCP into a node
# using global ssh settings.
# In addition, provide a password
# that is read in from a file.
# Use this to automate SSH / SCP before
# ssh keys are generated and copied to each node.
my_sshpass() {
  local user_ip=$1; shift
  local method=$1; shift
  local call=""
  local args=$@

  # If we want to SSH and execute commands on a node
  if [[ $method == "ssh" ]]; then

    call="$ssh_args $user_ip $args"

  # If we want to SCP a file to a node
  elif [[ $method == "scp" ]]; then

    call="$scp_args $args $user_ip:"

  # We want to copy a public key toa node
  elif [[ $method == "ssh-copy-id" ]]; then

    call="$ssh_args $args $user_ip"

  else
    echo "$method not supported"
    return 1
  fi

  # Make SSH or SCP call passing the password
  # in from a file to automate the process
  sshpass -p $COMMON_PASS $method $call
}

#-------------------------------------------------------------------------------

# Counts the number of lines in
# a file, ignore new line / empty strings.
# Prints it to console
num_lines() {
  local file="$@"

  cat $file | sed '/^\s*$/d' | wc -l
}

#-------------------------------------------------------------------------------

# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command. This function
# can run synchronously or asynchronously.
loop_nodes() {

  # NOTE - See: https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0

  # TODO - pass async as flag
  local file=$1; shift
  local action=$1; shift
  local async=1
  local args="$@"
  local pids=""
  local result=0

  # Loop through each ip address
  # listed in input file
  while read ip; do

    # Print the action that is being carried out
    echo "$action: $COMMON_USER@$ip"

    # Run in async mode. Essentially
    # kick off each subprocess and send
    # it to the background.
    if [[ "$async" -eq 0 ]]; then
      # 1. We are running an inner subprocess that will pipe stout
      # and stderr to a file
      # 2. This is all encapsulated in another subprocess that we throw into
      # the background. The outer most process' pid will be captured
      # and stored into an array. We can then await these processes as a group
      ( ( $action $COMMON_USER@$ip $args ) >> $LOG_DIR/$ip.log 2>&1 ) &

      # Keep a list of process ids
      pids="$pids $!"

    # Run synchronously. Wait for
    # each action to complete before
    # going onto the next action.
    else

      # Kick off a subprocess in foreground. Log its output to a file while
      # still making it visible on the console.
      ( ( $action $COMMON_USER@$ip $args ) 2>&1 | tee -a $LOG_DIR/$ip.log )
    fi
  done <$file

  # If we ran in async mode,
  # await all subprocesses' completion
  if [[ "$async" -eq 0 ]]; then

    # Show PID on console just incase we have
    # some orphan processes, we can easily cleanup.
    echo "Waiting for all processe(s) to finish:"
    printf '%s\n' "${pids[@]}"

    # Loop through pids and wait
    # for them to complete.
    for pid in $pids; do
      wait $pid || let "result=1"
    done

    # Check exit status
    # TODO - Create some sort of temporary
    # mapping between PID and ip so that we
    # know which node failed, and we know which
    # log file to check
    if [[ $result -ne 0 ]]; then
      echo "FAILURE - At least on process exited with a non-zero status"
    fi
  fi

  return $result
}

#-------------------------------------------------------------------------------

# SCP a set of files to each
# node that is specified in
# the global list of ips
scp_nodes() {

  loop_nodes "$IPS" my_scp "$@"
}

#-------------------------------------------------------------------------------

# Provided a list of node ips
# ($1) and a list of files
# (remaning arguments), SCP the files
# to each node ip in the list.
scp_specific_nodes() {
  local ip_list=$1; shift
  local args="$@"

  loop_nodes "$ip_list" my_scp $args
}

#-------------------------------------------------------------------------------

# Execute a command on each
# node that is specified in
# the global list of ips
ssh_nodes() {

  loop_nodes "$IPS" my_ssh "$@"
}

#-------------------------------------------------------------------------------

# SSH into a list of node specified
# by a file ($1), and execute the
# command that follow
ssh_specific_nodes() {
  local ip_list=$1; shift
  local args="$@"

  loop_nodes "$ip_list" my_ssh $args
}

#-------------------------------------------------------------------------------

# Sends a single and executes
# a command on each node in global
# list of ips
scp_ssh_nodes() {
  local file=$1; shift
  local args="$@"

  scp_nodes "$file"
  ssh_nodes "$args"
}

#-------------------------------------------------------------------------------

# Sends a single and executes
# a command on each node in specified
# list of ips
scp_ssh_specific_nodes() {
  local ip_list=$1; shift
  local file=$1; shift
  local args="$@"

  scp_specific_nodes "$ip_list" "$file"
  ssh_specific_nodes "$ip_list" "$args"
}

#-------------------------------------------------------------------------------

# Execute a command (ssh) or send
# a file (scp) to each node listed
# in global list of ips. This method
# pipes the password in via lastpass
# rather than relying on ssh keys. We
# use this function before we generate keys.
sshpass_nodes() {

  loop_nodes "$IPS" my_sshpass "$@"
}

#-------------------------------------------------------------------------------

# Execute a command (ssh) or send
# a file (scp) to each node listed
# in a specific list of ips. This method
# pipes the password in via lastpass
# rather than relying on ssh keys. We
# use this function before we generate keys.
sshpass_specific_nodes() {
  local ip_list=$1; shift
  local args="$@"

  loop_nodes "$ip_list" my_sshpass "$args"
}

#-------------------------------------------------------------------------------

# Completely removes all files and
# directories that are not hidden
# in the default working directory
# of each node. TODO - Prhaps change
# this so that we are not interfering
# with mounting our samba drives to home
# folder. This way we can have both a cluster
# and NAS goig at the same time
clean_workspace() {
  echo "Clearing remote working directory"
  local ip_list=$1
  local clean_script="clean_workspace.sh"

  echo "rm -rfv ./*" > $clean_script
  chmod +x $clean_script

  scp_ssh_specific_nodes "$ip_list" $clean_script ./$clean_script

  rm -f $clean_script
}

#-------------------------------------------------------------------------------

# Power off and power
# on each node.
reboot_nodes() {

  # Power off and reboot
  # each node in cluster
  # TODO - Need to ignore error when ssh is closed
  ssh_nodes echo "rebooting"; (sleep 1 && sudo reboot &) && exit
}

#-------------------------------------------------------------------------------

# Determines whether or
# not a command is is
# installed on a device
is_installed() {
  local program=$1

  # Call the command
  if "$program"; then
    return 0
  else
    return 1
  fi
}

#-------------------------------------------------------------------------------

# Print this device's ip
my_ip() {

  # TODO - Find platform independent way of
  # getting the ip address
  echo $(hostname -I | awk '{print $1}')
}

#-------------------------------------------------------------------------------

# Executes a given command after N seconds
# with a real time countdown and message.
delayed_action() {
  local delay=$1; shift
  local message=$1; shift
  local action="$@"
  local secs=$(( $delay ))

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

#-------------------------------------------------------------------------------

# Executes a command and
# displays how long it took
# to execute in seconds.
# TODO - Maybe give more meaningful
# output such as hh:mm:ss
timed_action() {
  local action=$1
  local START_TIME=$SECONDS

  "$@"
  local ELAPSED_TIME=$(($SECONDS - $START_TIME))
  echo "Completed $action in: $ELAPSED_TIME second(s)"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

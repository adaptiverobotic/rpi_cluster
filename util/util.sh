#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Declare global settings
# such as ssh and scp flags
declare_variables() {

  # Read general ssh flags in from a file because
  # there are a lot of them. We will use these for
  # both ssh and scp.
  readonly general_ssh_args="$(cat assets/ssh_args_file)"
  readonly ssh_args="$general_ssh_args"
  readonly scp_args="$general_ssh_args -r"
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

  # NOTE - Loop through each arg
  # and download one by one.
  # idk why but passing all at
  # once does not work.
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

# This function is the core of this util
# script that makes this application work.
# Provided a list of ips, and a command,
# this function will loop through each ip
# in the ip list and execute that command.
# This function is used with my_ssh, my_scp, etc,
# so the first argument is user@hostname. We
# can expand it to work for any command if
#  we create an auxiliary function that maps
# the command to a function in this util file
# or simply executes the command if it does not find
# a function in this util script. By default, this function
# runs asynchronously. That is, the process is kicked
# off on each ip. We do not wait for ip1 to finish before
# we start the command on ip2. If a list of ips that
# has exactly 1 ip in it is passed, this function will run
# in synchronous mode. For debugging purposes, we can
# override this and run in synchronous mode for N nodes
# by setting an environment variable $SYNC_MODE to be true.
# That way we reserve the right to run specific parts of
# our application in synchronous mode if that is necessary.
# Provided this asynchrounous nature, logging becomes out of order.
# We address this by logging to a log file associated with a given ip. The
# logfile will take the form 192.168.2.xxx.log. Both
# stdout and stderr are sent to this file in asynch and
# sync mode. However, in synch mode, stdout and stderr
# also appear on the console for easy debugging.
loop_nodes() {

  # NOTE - See: https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0

  local file=$1; shift
  local action=$1; shift
  local async=$SYNC_MODE
  local args="$@"
  local result=0
  local failed_pids=""
  local lines_in_files=$( num_lines "$file" )

  # Associative array mapping
  # process_id to ip_address.
  # We use this in async mode to
  # figure out which ip a given
  # call failed on by its associated
  # pid (and consequently, exit code)
  declare -A map_pid_ip

  # Make sure the file has at least one line
  if [[ $lines_in_files -eq 0 ]]; then
    echo "Empty file: $file"
    return 1
  fi

  # If we only have 1 node, we
  # might as well run in synchronous
  # mode so that we can see what's
  # happening. Good for debugging.
  if [[ $lines_in_files -eq 1 ]]; then
    async=false
  fi

  # $DEV_MODE overrides all settings
  if [[ $DEV_MODE = true ]]; then
    async=false
  fi

  # Loop through each ip address
  # listed in input file
  while read ip; do

    # Print the action that is being carried out
    echo "$action: $COMMON_USER@$ip"

    # Run in async mode. Essentially
    # kick off each subprocess and send
    # it to the background.
    if [[ "$async" = true ]]; then
      # 1. We are running an inner subprocess that will pipe stout
      # and stderr to a file by its associates ip address
      # 2. This is all encapsulated in another subprocess that we throw into
      # the background. The outer most process' pid will be captured
      # and stored into an array. We can then await these processes as a group
      ( ( $action $COMMON_USER@$ip $args ) >> $LOG_DIR/$ip.log 2>&1 ) &

      # Keep a list of process ids
      map_pid_ip[$!]=$ip

    # Run synchronously. Wait for
    # each action to complete before
    # going onto the next action.
    else

      # Kick off a subprocess in foreground. Log its output to a file while
      # still making it visible on the console.
      # NOTE - Careful using tee, if we want to capture exit status
      # we need set -o pipefail, otherwise we get exit 0 for everything
      # which will effectively negate the ffects of our global set -e
      (
        set -o pipefail
        $action $COMMON_USER@$ip $args  2>&1 | tee -a $LOG_DIR/$ip.log
      )

    fi
  done <$file

  # If we ran in async mode,
  # await all subprocesses' completion
  if [[ "$async" = true ]]; then

    # Show PID on console just incase we have
    # some orphan processes, we can easily cleanup.
    echo "Waiting for all processe(s) to finish..."

    # Loop through pids and wait
    # for them to complete.
    for pid in "${!map_pid_ip[@]}"
    do

      # TODO - Delete this once
      # we test on multiple nodes

      # echo "Process:"
      # echo "------------------"
      # echo "pid: $pid"
      # echo "ip:  ${map_pid_ip[$pid]}"
      # echo "------------------"

      # If a process failed,
      # push its pid onto a list
      # so that we know which logs
      # to check later
      if ! wait $pid; then

        # Push onto list of failed pids
        failed_pids="$failed_pids $pid"
        result=1
      else
        # NOTE - Reserve this for if
        # we want to do some sort of
        # logging by pid, currently,
        # do nothing
        :
      fi
    done

    # Print path to log files of failed nodes
    if [[ $result -ne 0 ]]; then
      echo ""
      echo "FAILURE - At least one process exited with a non-zero status"
      echo "Please see the following log file(s):"
      echo "-------------------------------------"

      # Loop through failed pids
      # and print their associated
      # log file paths.
      for pid in $failed_pids;
      do
        echo "$LOG_DIR/${map_pid_ip[$pid]}.log"
      done
      echo "-------------------------------------"
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

# Checks if a command runs
# successfully. We can specify
# the number of attempts before
# considering it a failure, as well
# as the delay between each attempt.
health_check() {
  local attempts=$(($1)); shift
  local action="$@"
  local counter=1

  while [ $counter -le $attempts ]; do

    if delayed_action $action; then
      echo "Success"
      return 0
    else
      echo "Failure: $(( $attempts - $counter )) attempt(s) remaining"
    fi

    ((counter++))
  done

  return 1
}

#-------------------------------------------------------------------------------

# Launches a browser
# and navigates to a
# specified url
launch_browser() {
  local browser=$1; shift
  local url=$@

  echo "Opening $url in $browser"

  if which $browser; then
    $browser $url
  else
    echo "Could not open browser, try opening it manually"
    return 1
  fi
}

#-------------------------------------------------------------------------------

# Execute a command and
# always make the exit
# status 0. This is convenient
# as all scripts in this
# ap have set -e
ignore_exit_status() {
  "$@" || true
}

#-------------------------------------------------------------------------------

# Displays the login url
# and credentials of the swarm
display_entry_point() {
  local url="$@"

  echo ""
  echo "You can access the swarm at: $url"
  echo ""
  echo "Credentials:"
  echo "-------------"
  echo "User: admin"
  echo "Password: $COMMON_PASS"
  echo "-------------"
  echo ""

  ignore_exit_status delayed_action 10 "Open_Chrome" launch_browser google-chrome $url
}

#-------------------------------------------------------------------------------

# Delete old log files
clear_logs() {
  echo "Clearing logs from: $LOG_DIR"

  rm -f $LOG_DIR/*
}

#-------------------------------------------------------------------------------

# Archives log files from
# previous deployments
archive_old_logs() {
  local old_log_dir="$ROOT_DIR/.logs.old"

  echo "Moving old logs from $LOG_DIR to $old_log_dir"

  # Make a folder for each log file
  for dir in $(ls "$LOG_DIR");
  do
    # TODO - Regex to remove .log
    mkdir -p "$old_log_dir"/"$dir"
  done

  # Copy each file from current to old
  # and append the deployment date. However,
  # we are not going to delete the old ones.
  # That's because this function is always followed
  # by clear_logs().
  for log in $(ls "$LOG_DIR");
  do
    cp "$LOG_DIR"/"$log" "$old_log_dir"/"$log"/"$log"-"$(cat $LAST_DEPLOYMENT)"
  done
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

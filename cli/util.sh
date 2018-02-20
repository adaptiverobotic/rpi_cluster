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
  readonly general_ssh_args="$(cat assets/config/ssh_args_file)"
  readonly ssh_args="$general_ssh_args"
  readonly scp_args="$general_ssh_args -r"

  # Default timeout 20 minutes
  readonly timeout_limit=9000
}

#-------------------------------------------------------------------------------

# Read a file in where each line
# has two space delimited values,
# and create. We loop through a file
# line by line, separating the first
# values between the first space and
# storing the first value as the key,
# and the second as the value in an
# associative array.
file_to_hashmap() {
  local file="$@"
  local key=""
  local val=""
  local entry=""
  declare -A hashmap

  while read line;
  do
    entry=($line)
    key=${entry[0]}
    val=${entry[1]}
    hashmap[$key]=$val
  done <$file

  declare -p hashmap
}

#-------------------------------------------------------------------------------

# Displays a associative
# array in the following form:
#
# key: <key_1> val: <val_1>
# key: <key_2> val: <val_2>
#             .
#             .
#             .
# key: <key_n> val: <val_n>
#
# NOTE - This is for debugging.
# Not really useful in practice.
print_hashmap() {
  local args="$@"

  # NOTE - This is the important line.
  # We use this is combination with the
  # aboe function file_to_hashmap() to
  # get hashmaps from files
  eval "declare -A hashmap="${args#*=}

  for key in "${!hashmap[@]}"; do
    printf 'key:%s \t val: %s\n' $key ${hashmap[$key]}
  done
}

#-------------------------------------------------------------------------------

# Prints a string in
# a specified color. If the
# color is not found, error out.
print_in_color() {
  local no_color="\033[0m"
  local color=$1; shift
  local c_message=$1; shift
  local nc_message=$1;
  local colors_file=${ROOT_DIR}/assets/config/colors
  local str=$(file_to_hashmap $colors_file)

  # Evaluate the declaration
  # string into a new associative array.
  eval "declare -A hashmap="${str#*=}

  # Get color from hashmap, print the colored message in specified
  # color, then print no color code, and print message without color
  echo -e "${hashmap[$color]}${c_message}${no_color}${nc_message}"
}

#-------------------------------------------------------------------------------

# Prints in cyan
print_advise() {
  print_in_color "cyan" "$@"
}

#-------------------------------------------------------------------------------

# Prints in red
print_error() {
  print_in_color "red" "$@"
}

#-------------------------------------------------------------------------------

# Prints in green
print_success() {
  print_in_color "green" "$@"
}

#-------------------------------------------------------------------------------

# Prints in yellow
print_warn() {
  print_in_color "yellow" "$@"
}

#-------------------------------------------------------------------------------

# Write to console warning about
# leader and managers having a
# fixed ip addres.
warn_static_ip() {
  echo ""
  print_warn "Make sure that the ip address(es) do(es) not change"
  print_warn "Either assign static ip(s) or reserve the dhcp lease(es)"
  echo ""
}

#-------------------------------------------------------------------------------

# Echos length of an array
# (or white space separated string)
length() {
  echo "$#"
}

#-------------------------------------------------------------------------------

# Echos length in characters
str_length() {
  echo -n "$@" | wc -c
}

#-------------------------------------------------------------------------------

# Prints N hyphens
# and a new line character
print_dashes() {
  for ((i=1;i<=$1;i++));
  do
     printf '-'
  done

  printf '\n'
}

#-------------------------------------------------------------------------------

# Echoes longest string
# in array
longest_string() {
  local array="$@"
  local max_str=$1

  # Get string with max length
  for val in $array;
  do
    x=$(str_length $val)
    y=$(str_length $max_str)
    if [[ $x > $y ]]; then
      max_str=$val
    fi
  done

  echo $max_str
}

#-------------------------------------------------------------------------------

# Takes a space separated list
# with a line above and below
# based off of the longest string
# in the list
print_as_list() {
  local message=$1; shift
  local args="$@"
  local str=$(longest_string $args)
  local num_dashes=$(str_length $str)

  echo ""
  echo $message
  print_dashes $num_dashes
  printf '%s\n' $@
  print_dashes $num_dashes
  echo ""
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
  ssh -t $ssh_args -n $user_ip "$args"
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

# Executes a give command. with
# a given timelimit. If the command
# takes too long, we will print a message
# saying we timed out and kill
# the process.
my_timeout() {
  local limit=$1; shift
  local exit_status=0

  # Don't let this loop for ever
  if ! timeout $limit $UTIL "$@"; then

    # TODO - Figure out how to capture
    # exit code from timeout
    # If timeout was the issue
    if [[ $? == 124 ]]; then
      echo "ERROR: Time out after $timeout_limit second(s)"
    fi

    exit_status=1
  fi

  return $exit_status
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
  local async=true
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

  # We will see everything that's
  # happening 1 node at a time.
  # slow but good for debugging.
  if [[ $DEV_MODE = true ]]; then
    async=false
  fi

  # Print the action being carried out
  # and the list of affected ip addresses
  print_as_list "$action:" $(cat $file)

  # Loop through each ip address
  # listed in input file and execute
  # the specified action for that ip
  while read ip; do

    # Run in async mode. Essentially
    # kick off each subprocess and send
    # it to the background.
    if [[ "$async" = true ]]; then

      # 1. We are running an inner subprocess that will pipe stout
      # and stderr to a file by its associates ip address
      # 2. This is all encapsulated in another subprocess that we throw into
      # the background. The outer most process' pid will be captured
      # and stored into an array. We can then await these processes as a group
       ( ( my_timeout $timeout_limit $action $COMMON_USER@$ip $args ) >> $LOG_DIR/$ip.log 2>&1 ) &

      # Keep an associative
      # array of pids to ips
      # for lookup later
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
        # TODO - Figure out how to add some prefix
        # to line that indicate that these logs are
        # coming front an ssh session rather than locally.
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
    echo "Waiting for ${#map_pid_ip[@]} processe(s) to finish..."

    # Loop through pids and wait
    # for them to complete.
    for pid in "${!map_pid_ip[@]}"
    do

      # If a process failed,
      # push its pid onto a list
      # so that we know which logs
      # to check later
      if ! wait $pid; then

        print_error "\xE2\x9D\x8C " "${map_pid_ip[$pid]}"

        # Push onto list of failed pids
        failed_pids="$failed_pids $pid"
        result=1
      else
        print_success "\xE2\x9C\x94 " "${map_pid_ip[$pid]}"
      fi
    done

    # Print path to log files of failed nodes
    if [[ $result -ne 0 ]]; then
      # TODO - Figure out how to get
      # a list of just of ips and send
      # that to the print_as_list() function
      print_error "FAILURE: " "$( length $failed_pids) process(s) exited with a non-zero status"
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

    else
      print_success "SUCCESS: " "All ${#map_pid_ip[@]} processe(s) completed successfully"
      echo ""
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
  local clean_script="${ASSETS}/temp/clean_workspace.sh"

  echo "rm -rfv ./*" > $clean_script
  chmod +x $clean_script

  scp_ssh_specific_nodes "$ip_list" $clean_script ./clean_workspace.sh

  rm -f $clean_script
}

#-------------------------------------------------------------------------------

# TODO - Put some sort of user defined delay
# for how long we will give a given node to
# turn back on. If not, consider it unreachable
# and error out. Perhaps this can be the same
# function that we use when we generate out ip
# list when we verify that a node is reachable.
# before it gets added to our global list of ips.

# Reboot all nodes
reboot_nodes() {

  # Power off and reboot
  # each node in cluster
  # TODO - Need to ignore error when ssh is closed
  ssh_nodes echo "Rebooting nodes"; (sleep 1 && sudo reboot &) && exit
}

#-------------------------------------------------------------------------------

# Power off and power
# on each node
restart_nodes() {
    ssh_nodes echo "Restarting nodes"; (sleep 1 && sudo restart &) && exit
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

# Given an ip
# print is mac address
get_mac_from_ip() {
  local ip=$1;

  # Get the mac address
  mac=$(arp -an $ip \
      | awk '{print $4}' \
      | tr -d '()')

  echo "$mac"
}

#-------------------------------------------------------------------------------

# Print this
# device's ip
my_ip() {

  # TODO - Find platform independent way of
  # getting the ip address
  # ip route get 8.8.8.8 | awk '{ print $NF; exit }'
  echo $(hostname -I | awk '{print $1}')
}

#-------------------------------------------------------------------------------
# Prints this
# device MAC
my_mac() {
  local ip=$(my_ip)
  local mac=$(get_mac_from_ip)

  # TODO - Implement without
  # going around the network

  echo "$mac"
}

#-------------------------------------------------------------------------------

# Print the subnet
# this device is on
my_subnet() {
  local ip=$(my_ip)
  echo ${ip%.*}
}

#-------------------------------------------------------------------------------

# Executes a given command after N seconds
# with a real time countdown and message.
delayed_action() {
  local delay=$1; shift
  local message=$1; shift
  local action="$@"
  local secs=$(( $delay ))

  # Count down
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
      print_success "SUCCESS: " "Health check passed"
      return 0
    else
      print_error "FAILURE: " "$(( $attempts - $counter )) attempt(s) remaining"
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

  # TODO - Why did I write this...?
  # Need to find better way to see if
  # the browser is installed, or open
  # default web browser
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
# from log directory
clear_logs() {
  echo "Clearing logs from: $LOG_DIR"
  rm -f $LOG_DIR/*
}

#-------------------------------------------------------------------------------

# Archives log files from
# previous deployments
# by doing the following:
#
# 1. Make a folder for each log file
#
# 2. Make a folder for each log file
#
# 3. Copy each file from current to old
# and append the deployment date.
#
# We are not going to delete the old logs yet.
# That's because this function is always followed
# by clear_logs().
archive_old_logs() {
  local old_log_dir="$ROOT_DIR/.logs.old"

  echo "Moving old logs from $LOG_DIR to $old_log_dir"

  # Make if does
  # not exist
  mkdir -p $LOG_DIR

  # If there are no old logs
  # to move, then exit
  if [[ ! -f "$LAST_DEPLOYMENT" ]]; then
    echo "Nothing to archive"
    return 0
  fi

  # 1. Make appropriate folders
  for dir in $(ls "$LOG_DIR");
  do
    # TODO - Regex to remove .log
    mkdir -p "$old_log_dir"/"$dir"
  done

  # 2 / 3. Copy and rename
  for log in $(ls "$LOG_DIR");
  do
    cp "$LOG_DIR"/"$log" "$old_log_dir"/"$log"/"$log"-"$(cat $LAST_DEPLOYMENT)"
  done
}

#-------------------------------------------------------------------------------

# Sorts a list of ips
# in either ascending or
# descending order based off
# othe first argument.
sort_ips() {
  local ips="$@"

  ./bin/sort_ips.o $ips
}

#-------------------------------------------------------------------------------

# Returns true if an only
# if we can ssh into the
# provide ip address
nodes_reachable() {
  local file="$@"

  echo "Checking that nodes are reachable"
  sshpass_specific_nodes $file ssh echo "Checking if nodes are reachable"
  print_success "SUCCESS: " "All nodes are reachable"
}

#-------------------------------------------------------------------------------

# Provided a file of ips,
# this function prints "true"
# and returns 0 if and only if
# each line in the file is a valid
# IPv4 address.
valid_ip_list() {
  local file="$@"
  local valid=0

  echo "Checking that all ips are valid IPv4 addresses"

  if [[ $(num_lines $file) < 1 ]]; then
    print_error "FAILURE: " "No ips in file"
    valid=1

  # Loop through each 1
  else

    # TODO - Duplicate code, this is implemented
    # in C code. Create small file that calls this
    # to keep shell scripts shorter. Let C do
    # the heavy lifting

    while read ip; do

      # Run C program that returns 0 for valid ips
      if ! ./bin/valid_ipv4.o "$ip" > /dev/null; then
        print_error "ERROR: " "Invalid ip $ip"
        valid=1
        break
      fi
    done <$file
  fi

  # Make sure all nodes are
  # reachable by ssh
  if [[ valid -eq 0 ]]; then
    print_success "SUCCESS: " "All ips are IPv4"
    echo "Checking that we can ssh into each ip"
    nodes_reachable $file

  else
    print_error "ERROR: " "All ips are not valid IPv4 addresses"
  fi

  if [[ valid -ne 0 ]]; then
    print_error "ERROR: " "Not all nodes are reachable"
  fi

  return $valid
}

#-------------------------------------------------------------------------------

# Returns 0 if and only
# if the hostname conforms
# to linux standards
valid_hostname() {
  local hostname="$@"
  local valid=0

  echo "Validating hostname: $hostname"

  # Run C program that returns 0 for valid hostnames
  if ! ./bin/valid_hostname.o $hostname > /dev/null; then
    valid=1
    print_error "FAILURE: " "Unacceptable hostname: $hostname"
  else
    print_success "SUCCESS: " "Acceptable hostname: $hostname"
  fi
  return $valid
}

#-------------------------------------------------------------------------------

# Returns 0 if and only
# if user conforms to
# standard
valid_user() {
  local user="$@"
  local valid=0

  echo "Validating user: $user"

  # Run C program that returns 0 for valid usernames
  if ! ./bin/valid_user.o $user > /dev/null; then
    print_error "FAILURE: " "Unacceptable user: $user"
    valid=1
  else
    print_success "SUCCESS: " "Acceptable user: $user"
  fi
  return $valid
}

#-------------------------------------------------------------------------------

# Returns 0 if and only
# if password conforms to
# standard
valid_password() {
  local password="$@"
  local valid=0

  echo "Validating password"

  # Run C program that returns 0 for valid passwords
  if ! ./bin/valid_password.o $password > /dev/null; then
    print_error "FAILURE: " "Unacceptable password"
    valid=1
  else
    print_success "SUCCESS: " "Acceptable password"
  fi
  return $valid
}

#-------------------------------------------------------------------------------

# Prints true if a list
# contains a search element,
# otherwise false. 0 is always
# returned as exit status
search_list() {
  local element=$1; shift
  local group=$@

  # Linear search
  for obj in $group;
  do
    if [[ $obj = $element ]]; then
      echo "true"
      return 0
    fi
  done

  echo "false"
}

# Checks if an element begins with
# any of the elements in the list
# that follows it
search_list_by_prefix() {
  local element=$1; shift
  local group=$@

  # Linear search
  for obj in $group;
  do
    if [[ $element == $obj* ]]; then
      echo "true"
      return 0
    fi
  done

  echo "false"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

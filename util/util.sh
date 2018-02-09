# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {

  # Give names to args
  # for easier reference
  file=$1
  protocol=$2

  echo "Looping each ip / host listed in: $file"
  echo "$(cat $file)"

  while read line; do
    echo "$protocol: $user@$line"

    # If we want to SSH
    if [[ $protocol == "ssh" ]]; then
      sshpass -f $password_file ssh -o userknownhostsfile=/dev/null -o stricthostkeychecking=no -n $user@$line "${@:3}"

    # If we want to SCP
    elif [[ $protocol == "scp" ]]; then
      sshpass -f $password_file scp -r ${@:3} $user@$line:

    else
      echo "Only SSH and SCP are supported protocols"
    fi
  done <$file
}

#-------------------------------------------------------------------------------

ssh_specific_nodes() {

  # Send file list first
  loop_nodes $1 ssh ${@:2}
}

#-------------------------------------------------------------------------------

scp_specific_nodes() {

  # Send file list first
  loop_nodes $1 scp ${@:2}
}

#-------------------------------------------------------------------------------

ssh_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $ips ssh "$@"
}

#-------------------------------------------------------------------------------

scp_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes $ips scp "$@"
}

#-------------------------------------------------------------------------------

reboot() {

  # Power off and reboot
  # each node in cluster
  ssh_nodes reboot -p
}

#-------------------------------------------------------------------------------

is_installed() {

  # Determines whether or
  # not a command is installed
  echo "0"
}

#-------------------------------------------------------------------------------

last_three() {
  echo $1 | cut -d . -f 4
}

#-------------------------------------------------------------------------------

lowest_ip() {

  while read $ip; do

    # Get last 3 digits from ip
    num=$(last_three $ip)

  done <$ips
}

#-------------------------------------------------------------------------------

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get login credential
user=$(cat ${DIR}/../assets/user)
password_file="${DIR}/../assets/password"
ips="${DIR}/../assets/ips"

"$@"

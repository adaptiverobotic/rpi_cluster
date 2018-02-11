set -e

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get login credential
user=$(cat ${DIR}/../assets/user)
password_file="${DIR}/../assets/password"
ips="${DIR}/../assets/ips"

ssh_args="
-o ConnectTimeout=5 \
-o IdentitiesOnly=yes \
-o userknownhostsfile=/dev/null \
-o stricthostkeychecking=no"

#-------------------------------------------------------------------------------

my_ssh() {
  user=$1
  ip=$2

  sshpass -f $password_file ssh $ssh_args -n $user@$ip "${@:3}"
}

#-------------------------------------------------------------------------------

my_scp() {
  user=$1
  ip=$2

  sshpass -f $password_file scp $ssh_args -r "${@:3}" $user@$ip:
}

#-------------------------------------------------------------------------------

# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {

  # Give names to args
  # for easier reference
  file=$1
  action=$2

  while read ip; do
    echo "Action: $action: $user@$ip"

    # If we want to SSH
    if [[ $action == "ssh" ]]; then

      my_ssh $user $ip "${@:3}"

    # If we want to SCP
    elif [[ $action == "scp" ]]; then

      my_scp $user $ip "${@:3}"

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

reboot_nodes() {

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

my_ip() {

  # NOTE - LINUX ONLY
  tmp0=$(hostname -I)
  tmp1=($tmp0)
  i=${tmp1[0]}
  echo $i
}

#-------------------------------------------------------------------------------

"$@"

# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {

  # Give names to args
  # for easier reference
  protocol=$1
  file=$ips

  echo "Looping each ip / host listed in: $file"
  echo "$(cat $file)"

  while read line; do
    echo "$protocol: $user@$line"

    # If we want to SSH
    if [[ $protocol == "ssh" ]]; then
      ssh -n $user@$line "${@:2}"

    # If we want to SCP
    elif [[ $protocol == "scp" ]]; then
      scp -r ${@:2} $user@$line:

    else
      echo "Only SSH and SCP are supported protocols"
    fi
  done <$file
}

#-------------------------------------------------------------------------------

ssh_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes ssh "$@"
}

#-------------------------------------------------------------------------------

scp_nodes() {

  # Loop through nodes and
  # run a specified script
  loop_nodes scp "$@"
}

#-------------------------------------------------------------------------------

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get login credentials
user=$(cat ${DIR}/../assets/user)
ips="${DIR}/../assets/ips"

"$@"

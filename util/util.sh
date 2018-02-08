# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {

  # Give names to args
  # for easier reference
  protocol=$1
  user=$2
  file=$3

  echo "Looping each node in $file"
  echo "$(cat $file)"

  while read line; do

    # If we want to SSH
    if [[ $protocol == "ssh" ]]; then
      echo "SSH: $user@$line"
      ssh -n -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$line "${@:4}"

    # If we want to SCP
    elif [[ $protocol == "scp" ]]; then
      echo "SCP: $user@$line"
      scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${@:4} $user@$line:

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

"$@"

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

  while read line; do

    # If we want to SSH
    if [[ $protocol == "ssh" ]]; then
      echo "SSH: $user@$line"
      ssh -n $user@$line "${@:3}"

    # If we want to SCP
    elif [[ $protocol == "scp" ]]; then
      echo "SCP: $user@$line"
      scp -r ${@:3} $user@$line:

    # TODO - Notify command not recognized otherwise

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

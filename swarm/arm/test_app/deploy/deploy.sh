# Generates list of nodes by hostname
node_hostnames() {
  node_file=assets/nodes

  # Delete if exists
  rm -f $node_file

  # Recreate files
  touch $node_file

  # Write out to temp file
  temp=$(docker node ls -q | xargs docker node inspect -f '{{ .Description.Hostname }}')

  # Break up into array
  nodes=($temp)

  # Loop through array and Write
  # line by line
  for i in "${nodes[@]}"
  do
     :
     echo ${nodes[i]} >> $node_file
  done
}

#-------------------------------------------------------------------------------

# Loop through each node and either SCP
# files to it, or SSH into it and execute
# a specified script / command.
loop_nodes() {
  echo "Looping each node"

  while read line; do

    # If we want to SSH
    if [[ $1 == "ssh" ]]; then
      echo "SSH: $user@$line"
      ssh -n $user@$line "${@:2}"

    # If we want to SCP
    elif [[ $1 == "scp" ]]; then
      echo "SCP: $user@$line"
      scp -r ${@:2} $user@$line:

    # TODO - Notify command not recognized otherwise

    fi
  done <assets/nodes
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

send_assets() {

  # Loop through each node, SCP into each one and
  # send all of these files to the node
  scp_nodes assets setup.sh docker.sh clean.sh
}

#-------------------------------------------------------------------------------

setup_nodes() {

  # Loop through nodes and
  # run setup script
  ssh_nodes ./setup.sh
}

#-------------------------------------------------------------------------------

clean_nodes() {
  echo "Cleaning nodes"

  # Loop through nodes and
  # run cleanup script
  ssh_nodes ./clean.sh assets/clean
}

#-------------------------------------------------------------------------------

init() {
  # Send required files
  # to nodes over SCP first
  send_assets

  # Clean old data off nodes
  # (volumes, images, containers)
  clean_nodes

  # Set up nodes (create volumes, etc.)
  setup_nodes

  # Initialize docker networks (once)
  ./docker.sh network assets/networks

  # Tag and build new images locally
  ./docker.sh build assets/images
}

#-------------------------------------------------------------------------------

services() {
  init

  # Deploy services to swarm
  ./docker.sh service assets/services
}

#-------------------------------------------------------------------------------

stack() {
  init

  # Deploy stack to swarm
  docker stack deploy -c ../docker-compose.yml $(cat assets/stack)
}

#-------------------------------------------------------------------------------

# Get the common username
# from the user file
user=$(cat assets/user)

# Generate list of node hostnames
node_hostnames

"$@"

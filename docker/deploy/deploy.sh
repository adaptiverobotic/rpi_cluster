# Generates list of nodes by hostname
node_hostnames() {
  echo "Compiling list of nodes by hostname"

  # Delete list file if it exists
  rm -f $1

  # Recreate the file
  touch $1

  # Run docker command to get list of nodes by hostname as space delimited list
  temp=$(docker node ls -q | xargs docker node inspect -f '{{ .Description.Hostname }}')

  # Break up into array
  nodes=($temp)

  # Loop through array and write
  # the line by line
  for i in "${nodes[@]}"
  do
     :
     echo $i >> $1
  done
}

#-------------------------------------------------------------------------------

compile_assets() {
  echo "Compiling all asset files into one central location"
  cp -r $root_assets. $assets
  cp -r $app_assets. $assets
}

#-------------------------------------------------------------------------------

clear_assets() {
  echo "Removing temporary assets directory and its contents"

  # TODO - Maybe not delete
  # so destructively
  rm -rf $assets
}

#-------------------------------------------------------------------------------

send_assets() {
  echo "Sending assets to all nodes in swarm"

  # Compile assets from root and
  # test app into one directory
  compile_assets

  # Loop through each node, SCP into each one and
  # send all of these files to the node
  $scp_nodes $user $node_file $assets docker.sh
}

#-------------------------------------------------------------------------------

setup_nodes() {
  echo "Running install script on node"

  # Loop through nodes and run setup script
  $ssh_nodes $user $node_file ./docker.sh setup
}

#-------------------------------------------------------------------------------

clean_nodes() {
  echo "Cleaning old volumes, images, and containers from each node"

  # Loop through nodes and run cleanup script
  $ssh_nodes $user $node_file ./docker.sh cleanup assets/clean ./
}

#-------------------------------------------------------------------------------

pull_nodes() {
  echo "Pulling images down from docker hub"

  # Loop through nodes and pull images down locally
  $ssh_nodes $user $node_file ./docker.sh pull assets/images ./
}

#-------------------------------------------------------------------------------

init() {
  echo "Initializing each node"

  # Send required files
  # to nodes over SCP first
  send_assets

  # Clean old data off nodes
  # (volumes, images, containers)
  clean_nodes

  # Set up nodes (create volumes, etc.)
  setup_nodes

  # Initialize docker networks (once for entire swarm)
  ./docker.sh network ${assets}networks

  # Tag and build new images locally
  ./docker.sh build ${assets}images $app_path

  # Push images to docker hub
  ./docker.sh push ${assets}images

  # Pull images down
  # to each node
  pull_nodes
}

#-------------------------------------------------------------------------------

services() {
  echo "Starting each service individually"

  # Initialize each node
  init

  # Deploy services to swarm
  ./docker.sh service ${assets}services $app_path
}

#-------------------------------------------------------------------------------

stack() {
  echo "Starting services via docker deploy stack"

  # Initialize each node
  init

  # Deploy stack to swarm
  docker stack deploy -c ${app}docker-compose.yml $(cat ${assets}stack)
}

#-------------------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# For fully qualified paths
# when passing files to scripts
# that are in different directories
root_path="${DIR}/../../"
app_path="${DIR}/../test_app/"

# All paths to asset files
root_assets="${root_path}assets/"
app_assets="${app_path}assets/"
assets="${DIR}/assets/"

# Alias to import util script
util="/bin/bash ${root_path}util/util.sh"

# Alias to functions in util script
scp_nodes="${util} scp_nodes"
ssh_nodes="${util} ssh_nodes"

# File with list of hostnames
# of nodes in docker swarm
node_file="${assets}nodes"

# Get the common username
# from the user file
user=$(cat ${root_assets}user)

# Create assets folder if it
# does not already exist
mkdir -p $assets

# Generate list of node hostnames
node_hostnames $node_file

# Run function specified
# by command line argumens
"$@"

# Clear assets from temporary
# assets folder
clear_assets

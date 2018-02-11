#!/bin/bash
set -e

compile_assets() {
  # Compile assets from root and
  # test app into one directory
  echo "Compiling all asset files into one central location"
  cp -r ${DIR}/../assets/. $assets
  cp -r ${app_path}assets/. $assets
}

send_assets() {
  # Send required files
  # to nodes over SCP first
  echo "Sending assets to all nodes in swarm"

  # Loop through each node, SCP into each one and
  # send all of these files to the node
  $scp_nodes $assets ${DIR}/docker.sh
}

clean_nodes() {
  # Clean old data off nodes
  # (volumes, images, containers)
  echo "Cleaning old volumes, images, and containers from each node"

  # Loop through nodes and run cleanup script
  $ssh_nodes ./docker.sh cleanup assets/clean ./
}

setup_nodes() {
  # Set up nodes (create volumes, etc.)
  echo "Running install script on node"

  # Loop through nodes and run setup script
  $ssh_nodes ./docker.sh setup_app
}

pull_images() {
  # Loop through nodes and pull images down locally
  echo "Pulling images down from docker hub"
  $ssh_nodes ./docker.sh pull assets/images ./
}

init() {
  echo "Initializing each node"

  compile_assets

  send_assets

  clean_nodes

  setup_nodes
}

scp_service_files() {
  service_file_list="${DIR}/assets/service_file_list"

  # Get paths to all docker_service files
  find $app_path -name docker_service.sh > $service_file_list


  while read path; do
    # Get the name of the directly directly containing the
    # docker_service.sh script. We don't care about
    # the full path. We will use this to rename the scripts
    # so that once we SCP them to a node, they have unique names
    base_dir=$(basename $(dirname \"$path\"))

    service_file=${DIR}/assets/docker_service_${base_dir}.sh

    # Erase contents of file
    # if it already exists
    echo "" > $service_file

    # Copy the new script line by line
    # NOTE - using cat did not work because
    # it read the shebang onto the same line
    # as command, thus commenting the entire script
    while read line;do
      echo $line >> $service_file
    done <$path

  done <$service_file_list
}

service() {

  # Run required
  # initialization
  # on eaach node
  init

  # Run setup for app. This is run once on the manager.
  # We create the required networks, etc.
  $ssh_specific_nodes $leader ./docker.sh setup_app ./

  # Pull all images
  # down to each node
  pull_images
}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Deploying: $2"

# For fully qualified paths
# when passing files to scripts
# that are in different directories
app_path=$2

# All paths to asset files
assets="${DIR}/assets/"
mkdir -p $assets

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to functions in util script
scp_nodes="${util} scp_nodes"
ssh_nodes="${util} ssh_nodes"
ssh_specific_nodes="${util} ssh_specific_nodes"

# File with list of ips
# of nodes in docker swarm
ips="${DIR}/../assets/ips"
leader="${DIR}/../assets/leader"

$@

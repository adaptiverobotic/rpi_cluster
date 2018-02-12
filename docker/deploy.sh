#!/bin/bash
set -e

clear_assets() {
  echo "Deleting old asset files (remote and local)"

  # Cleans the remove home directory
  # of each node. That way we do not
  # accidently read in asset files
  # from a previous deployment.
  echo "Deleting remote asset files"
  ${util} clean_workspace $ips

  echo "Deleting local asset files"
  rm -vf ${assets}*
}

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

  # Remove old services
  $ssh_specific_nodes $leader ./docker.sh clean_services assets/services

  # Remove old networks
  $ssh_specific_nodes $leader ./docker.sh clean_networks assets/networks

  # Remove old secrets
  $ssh_specific_nodes $leader ./docker.sh clean_secrets assets/secrets
}

pull_images() {
  # Loop through nodes and pull images down locally
  echo "Pulling images down from docker hub"
  $ssh_nodes ./docker.sh pull assets/images ./
}

create_volumes() {
  echo "Creating volumes on nodes"

  # Create volume on each node
  $ssh_nodes ./docker.sh volume assets/volumes
}

create_networks() {
  echo "Creating networks for swarm"

  $ssh_specific_nodes $leader ./docker.sh network assets/networks
}

create_secrets() {
  echo "Creating secrets for swarm"

  $ssh_specific_nodes $leader ./docker.sh secret assets/secrets
}

init() {
  echo "Initializing each node"

  clear_assets

  compile_assets

  send_assets

  clean_nodes

  create_volumes

  create_networks

  create_secrets

  # build_images

  # push_images

  # Pull all images
  # down to each node
  pull_images
}

scp_service_file() {
  # TODO - Perhaps instead of scanning with
  # find, read in from assets/services. This
  # way the user can specify the order of deployment
  # rather than an auto generated alphabetically
  # sorted list. This also makes it easier to
  # implement the "depends_on" feature that
  # docker stack deploy does not have. Ultimately,
  # we can avoid wasted containers that keep restarting
  # while they wait for the services they depend on to come up.

  echo "Generative docker_service.sh script"

  service_file="${DIR}/assets/docker_service.sh"
  service_file_list="${DIR}/assets/service_file_list"

  # Get paths to all docker_service files
  find $app_path -name docker_service.sh > $service_file_list
  echo "" > $service_file

  # Loop through each service file
  # and create a script for it will a
  # unique name
  while read path; do

    # Get rid of the backslashes and append contents
    # of each docker_service.sh script
    echo $(cat $path)  | tr '\\' ' ' >> $service_file

  done <$service_file_list

  # Make it executable
  chmod 777 $service_file

  # Send the docker_service.sh to leader, and run it
  $scp_specific_nodes $leader $service_file
}

service() {

  # Run required
  # initialization
  # on eaach node
  init

  # Generate and send docker_service.sh
  # file over to leader node
  scp_service_file

  # Execute docker_service.sh to kick off the services
  $ssh_specific_nodes $leader ./docker_service.sh
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
scp_specific_nodes="${util} scp_specific_nodes"

# File with list of ips
# of nodes in docker swarm
ips="${DIR}/../assets/ips"
leader="${DIR}/../assets/leader"

$@

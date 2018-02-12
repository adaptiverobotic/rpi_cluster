#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Deploying: $2"

# For fully qualified paths
# when passing files to scripts
# that are in different directories
app_path=$2

# All paths to asset files
mkdir -p assets

leader="${ASSETS}/leader"

clear_assets() {
  echo "Deleting old asset files (remote and local)"

  # Cleans the remove home directory
  # of each node. That way we do not
  # accidently read in asset files
  # from a previous deployment.
  echo "Deleting remote assets"
  ${UTIL} clean_workspace $IPS

  echo "Deleting local assets"
  rm -vf assets/*
}

compile_assets() {

  # TODO - Perhaps instead of compiling
  # into this assets folder, perhaps we
  # could just scp assets from root, from app,
  # and from here over to the node separately.
  # That way we do not have to continuously
  # clear and compile. We can also have persistent
  # assets such as port number, or dependencies
  # for future improvement and modularization
  # of the install / deploy process

  # Compile assets from root and
  # test app into one directory
  echo "Compiling all asset files into one central location"
  cp -r ${ASSETS}/. assets/
  cp -r ${app_path}assets/. assets/
}

send_assets() {
  # Send required files
  # to nodes over SCP first
  echo "Sending assets to all nodes in swarm"

  # Loop through each node, SCP into each one and
  # send all of these files to the node
  $UTIL scp_nodes $(pwd)/assets/ $(pwd)/docker.sh
}

clean_nodes() {
  # Clean old data off nodes
  # (volumes, images, containers)
  echo "Cleaning old volumes, images, and containers from each node"

  # Remove old services. This should kill associated containers
  $UTIL ssh_specific_nodes $leader ./docker.sh clean_services assets/services

  # Loop through nodes and run cleanup script
  $UTIL ssh_nodes ./docker.sh cleanup assets/clean ./

  # Remove old networks that are associated with the service
  $UTIL ssh_specific_nodes $leader ./docker.sh clean_networks assets/networks

  # Remove old secrets that are associate with the service
  $UTIL ssh_specific_nodes $leader ./docker.sh clean_secrets assets/secrets
}

build_images() {
  echo "Building images locally"
  $UTIL ssh_specific_nodes $leader ./docker.sh build assets/build ./
}

push_images() {
  echo "Pushing images to docker registry"
  $UTIL ssh_specific_nodes $leader ./docker.sh push assets/push ./
}

pull_images() {
  # Loop through nodes and pull images down locally
  echo "Pulling images down from docker hub"
  $UTIL ssh_nodes ./docker.sh pull assets/images ./
}

create_volumes() {
  echo "Creating volumes on nodes"

  # Create volume on each node
  $UTIL ssh_nodes ./docker.sh volume assets/volumes
}

create_networks() {
  echo "Creating networks for swarm"

  $UTIL ssh_specific_nodes $leader ./docker.sh network assets/networks
}

create_secrets() {
  echo "Creating secrets for swarm"

  $UTIL ssh_specific_nodes $leader ./docker.sh secret assets/secrets
}

init() {
  echo "Initializing each node"

  # Delete old assets
  clear_assets

  # Collect new assets
  compile_assets

  # Send assets to nodes
  send_assets

  # Clean old images, volumes etc.
  clean_nodes

  # Create necessary volumes
  create_volumes

  # Create required networks
  create_networks

  # Create swarm secrets
  create_secrets

  # Build from source localy
  build_images

  # Push build images to registry
  push_images

  # Pull images on each node
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

  service_file="$( pwd )/assets/docker_service.sh"
  service_file_list="$( pwd )/assets/service_file_list"

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
  $UTIL scp_specific_nodes $leader $service_file
}

service() {

  # Initialze each node
  init

  # Generate docker_service.sh
  # and send it to leader
  scp_service_file

  # Execute docker_service.sh to kick off the services
  $UTIL ssh_specific_nodes $leader ./docker_service.sh
}

$@

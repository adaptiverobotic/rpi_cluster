#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Initialize global variables
# that will be reused throughout
# this script.
declare_variables() {
  # For fully qualified paths
  # when passing files to scripts
  # that are in different directories
  app_path=$1

  # File with ip of leader that
  # will facilitate the swarm creation
  # on the cluster side
  leader_file="${ASSETS}/leader"

  # All path to asset files
  mkdir -p assets
}

#-------------------------------------------------------------------------------

# Cleans the remove home directory
# of each node. That way we do not
# accidently read in asset files
# from a previous deployment.
clear_assets() {
  echo "Deleting old asset files (remote and local)"

  echo "Deleting remote assets"
  ${UTIL} clean_workspace $IPS

  echo "Deleting local assets"
  rm -f assets/*
}

#-------------------------------------------------------------------------------

# Compiles assets from the proided
# app directory and merges it with
# the local docker assets.
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

#-------------------------------------------------------------------------------

# Sends all of the asset
# files to each node.
send_assets() {
  # Send required files
  # to nodes over SCP first
  echo "Sending assets to all nodes in swarm"

  # Loop through each node, SCP into each one and
  # send all of these files to the node
  $UTIL scp_nodes $(pwd)/assets/ $(pwd)/docker.sh
}

#-------------------------------------------------------------------------------

# Build specified images from
# source on leader
build_images() {
  echo "Building images locally"
  $UTIL ssh_specific_nodes $leader_file ./docker.sh build assets/build ./
  echo "Successfully build images locally"
}

#-------------------------------------------------------------------------------

# Push specified images to
# docker registry.
push_images() {
  echo "Pushing images to docker registry"
  $UTIL ssh_specific_nodes $leader_file ./docker.sh push assets/push ./
  echo "Successfully pushed all images to docker register"
}

#-------------------------------------------------------------------------------

# Pull specified
# images from docker registry
# down to each node.
pull_images() {

  # Loop through nodes and pull images down locally
  echo "Pulling images down to each node from docker registry"
  $UTIL ssh_nodes ./docker.sh pull assets/images ./
  echo "Successfully pulled images to each node"
}

#-------------------------------------------------------------------------------

# Create local volumes
# that are specified by a list.
# TODO - Figure out how to
# create volumes that will be
# actually used by a serice.
create_volumes() {
  echo "Creating volumes on nodes"
  $UTIL ssh_nodes ./docker.sh volume assets/volumes
  echo "Successfully created all volumes"
}

#-------------------------------------------------------------------------------

# Create required networks
# that are specified in assets/networks
create_networks() {
  echo "Creating networks for swarm"
  $UTIL ssh_specific_nodes $leader_file ./docker.sh network assets/networks
  echo "Successfully created swarm networks"
}

#-------------------------------------------------------------------------------

# Create required networks
# that are specified in assets/secrets
create_secrets() {

  # SSH into leader node, and create new secrets
  echo "Creating secrets for swarm"
  $UTIL ssh_specific_nodes $leader_file ./docker.sh secret assets/secrets
  echo "Successfully created swarm secrets"
}

#-------------------------------------------------------------------------------

# Removes all services
# specified in the services file
clean_services() {
  # Remove old services. This should kill associated containers
  echo "Removing old services"
  $UTIL ssh_specific_nodes $leader_file ./docker.sh clean_services assets/services
  echo "Successfully removed old services"
}

#-------------------------------------------------------------------------------

# Removes all swarm networks
# specified in networks file
clean_networks() {
  # Remove old networks that are associated with the service
  echo "Removing old networks"
  $UTIL ssh_specific_nodes $leader_file ./docker.sh clean_networks assets/networks
  echo "Successfully removed old networks"
}

#-------------------------------------------------------------------------------

# Removes all swarm secrets
# specified in the secrets file
clean_secrets() {
  # Remove old secrets that are associate with the service
  echo "Removing old secrets"
  $UTIL ssh_specific_nodes $leader_file ./docker.sh clean_secrets assets/secrets
  echo "Successfully removed old secrets"
}

#-------------------------------------------------------------------------------

# Runs cleanup function on
# all nodes in swarm
cleanup() {
  # Loop through nodes and run cleanup script
  echo "Cleaning up on each node"
  $UTIL ssh_nodes ./docker.sh cleanup assets/clean ./
  echo "Successfully cleaned up each node"
}

#-------------------------------------------------------------------------------

# Cleans all old images, volumes, containers,
# etc that are associated with the service
# we want to deploy. This way we always have the
# latest images, etc.
clean_nodes() {
  # Clean old data off nodes
  # (volumes, images, containers)
  echo "Cleaning old volumes, images, and containers, etc from each node"

  # Remove swarm services
  clean_services

  # Run worker cleanup
  cleanup

  # Remove swarm networks
  clean_networks

  # Remove swarm secrets
  clean_secrets

  echo "Succesffuly cleaned old volumes, images, and containers, etc from each node"
}

#-------------------------------------------------------------------------------

# Creates new images, volumes, containers,
# etc that are associated with the service
# we want to deploy. This way we always have the
# latest images, etc.
prepare_nodes() {
  echo "Creating new volumes, images, and containers, etc from each node"

  # TODO - Implement create process the same way as we clean so that
  # this script has less functions, and we let the docker.sh handle
  # looping through a 'create' file to figure out which things to create

  # Create necessary volumes
  create_volumes

  # Create required networks
  create_networks

  # Create swarm secrets
  create_secrets

  echo "Successfully created new volumes, images, and containers, etc from each node"
}

#-------------------------------------------------------------------------------

# Executes all necessary steps to
# stand up a new service / stack.
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

  # Create new images, volumes etc.
  prepare_nodes

  # Build from source locally
  build_images

  # Push build images to registry
  push_images

  # Pull images on each node
  pull_images

  echo "Successfully initialized each nodes"
}

#-------------------------------------------------------------------------------

generate_service_script() {
  # TODO - Perhaps instead of scanning with
  # find, read in from assets/services. This
  # way the user can specify the order of deployment
  # rather than an auto generated alphabetically
  # sorted list. This also makes it easier to
  # implement the "depends_on" feature that
  # docker stack deploy does not have. Ultimately,
  # we can avoid wasted containers that keep restarting
  # while they wait for the services they depend on to come up.

  echo "Generating service deployment script"

  service_file="$( pwd )/assets/docker_service.sh"
  service_file_list="$( pwd )/assets/service_file_list"

  # Get paths to all docker_service files
  find $app_path -name docker_service.sh > $service_file_list

  # Erase old service_file
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
  chmod +x $service_file

  echo "Succesfully generated deployment script"
}

#-------------------------------------------------------------------------------

# Generate a global docker_service.sh
# file that is composed of all service
# files found in the subdirecries of
# the app path. Effectively, we are
# copying some features from docker stack.
send_service_script() {
  echo "Sending deployment script to leader: $(cat "$leader_file")"
  $UTIL scp_specific_nodes $leader_file $service_file
  echo "Succesfuly sent deployment script to leader: $(cat "$leader_file")"
}

#-------------------------------------------------------------------------------

execute_service_script() {
  echo "Executing deployment script on leader: $(cat "$leader_file")"
  $UTIL ssh_specific_nodes $leader_file ./docker_service.sh
  echo "Successfully executed deployment script on leader: $(cat "$leader_file")"
}

#-------------------------------------------------------------------------------

# This function facilitates running
# docker services on the swarm.
service() {

  # Initialze each node
  # TODO - We should not
  # init inside of deployment.
  # deploy should assume that
  # there is a swarm to deploy to.
  init

  # Generate docker_service.sh
  generate_service_script

  # Send service script to leader
  send_service_script

  # Start services
  execute_service_script
}

portainer() {
  # NOTE - Don't care about deploying
  # other stuff. Scripts are getting too
  # complicated.

  echo "Deploying portainer"
}

#-------------------------------------------------------------------------------

main() {
  echo "Deploying app from: $2"

  declare_variables "${@:2}"

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

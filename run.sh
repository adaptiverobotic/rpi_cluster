

#!/bin/bash
set -e

# Make sure every script is
# runnable with ./script_name.sh syntax
# That way the appropriate shell
# (bash, sh, expect) is run for each script
chmod 777 **/*.sh

ip_list() {
  echo "Generating list of ips"

  # Build ip address list
  ./ip/list.sh
}

ssh_keys() {
  echo "Generating ssh keys and copying it to all nodes"

  # Enable passwordless ssh
  ./ssh/install.sh
}

hostname() {
  echo "Changing each node's hostname to match a specified pattern"

  # Change all the hostnames
  ./hostname/change.sh
}

dependencies() {
  echo "Installing dependencies on all nodes"

  # Install dependencies
  ./dependencies/install.sh
}

firewall() {
  echo "Configuring each nodes' firewall"

  # Configure firewall
  ./ufw/install.sh
}

install_samba() {
  echo "Setting up each node as a network attached storage"

  # Setup network attached storage
  ./samba/install.sh
}

uninstall_samba() {
  echo "Uninstalling samba from cluster"
}

install_docker() {
  echo "Creating docker cluster"

  # Initialize docker swarm
  ./docker/install.sh
}

uninstall_docker() {
  echo "Uninstalling docker from cluster"
}

install_kubernetes() {
  echo "Creating kubernetes cluster"
}

uninstal_kubernetes() {
  echo "Uninstalling kubernetes from cluster"
}

deploy() {

  # Deploys an application to
  # a given cluster provider
  # (docker swarm, kuberneters, mesos)

  # Just for clarity
  provider=$1
  app_dir=$2

  echo "Deploying test app to $provider cluster"

  # Deploy test application
  ./$1/deploy.sh $2 ${@:3}
}

init() {
  provider=$1
  echo "Initializing cluster settings for: $provider"

  # Create a global list of ip
  # addresses that represent the
  # list of nodes that will be in
  # the cluster
  ip_list $provider

  # Generate ssh keys, and ship
  # the public keys to each node
  # to enable passwordless access
  ssh_keys

  # Change all of the hostnames
  # in the cluster to some common
  # naming convention
  hostname $provider

  # TODO - Download dependencies
  # depending on waht we are deploying.
  # Example, we do not want to download
  # kubernetes if we are deploying docker swarm
  dependencies $provider

  # TODO - Open ports depending on
  # what we are deploying. Example, if
  # we are only deploying SAMBA, then we
  # do not need to open docker ports
  firewall $provider
}

# Sets up cluster as a docker
# swarm cluster, and deploys
# Portainer to the cluster for
# easy docker swarm management
docker_cluster() {
  init docker

  install_docker

  deploy docker service ./docker/service/portainer/


  /bin/bash util/util.sh delayed_action 5 'Launching Google Chrome in' google-chrome $(cat assets/leader):9000
}

# Sets up cluster as a
# kubernetes cluster
kubernetes_cluster() {
  init kubernetes

  install_kubernetes

  deploy kubernetes service ./apps/test_app/
}

# Sets up each node in the
# the cluster as a Network
# Attached Storage (NAS).
samba_cluster() {
  init samba

  install_samba
}

$@

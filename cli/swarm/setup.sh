#!/bin/bash
set -e

#-------------------------------------------------------------------------------

# Run portainer service
# on swarm so we manage
# through web console.
start_portainer() {
  local user=$1
  local pass=$2

  echo "Starting portainer as docker service"

  # Pull image from docker registry
  echo "Pulling docker image portainer/portainer from docker registry"
  docker pull portainer/portainer

  # Create admin password as a docker secret
  echo "Changing default admin password"
  echo -n $pass | docker secret create portainer-pass -

  # Launch as detached process
  echo "Launching portainer"
  docker service create \
  --detach \
  --name portainer \
  --secret portainer-pass \
  --mode global \
  --publish mode=host,target=9000,published=9000 \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  portainer/portainer \
  --admin-password-file '/run/secrets/portainer-pass' \
  -H unix:///var/run/docker.sock
}

#-------------------------------------------------------------------------------

# Removes a node from
# a preexisting swarm.
leave_swarm() {
  echo "Leaving swarm"

  # Check if a node is in a swarm or not.
  # TODO - Maybe we should find a better way of
  # making sure that we are removed. Because if we
  # don't successfully leave, but continue the script,
  # then we will run into issues.
  if docker swarm leave --force; then
    echo "Successfully left swarm"
  else
    echo "This node was not part of a swarm or could not leave"
  fi
}

#-------------------------------------------------------------------------------

# Initializes a new swarm with
# this device (node) as the leader.
# We then generate join scripts
# that other nodes will execute to
# join this node's swarm.
init_swarm() {

  # Get this device's ip address
  ip=$(hostname -I | awk '{print $1}')

  # Make a new swarm.
  echo "Initializing swarm, advertising ip: $ip"

  # Generate join token but pipe stdout to /dev/null
  # so the join token is not exposed in the logs.
  docker swarm init --advertise-addr "$ip" > /dev/null

  # Get the join-token commands for workers and managers and pipe
  # the output into respective script files. These script files
  # will be sent to and run on the appropriate nodes
  echo "Generating join tokens for joining the new swarm"
  docker swarm join-token worker | grep "docker" > worker_join_token.sh
  docker swarm join-token manager | grep "docker" > manager_join_token.sh

  # Make the tokens runnable scripts
  chmod +x worker_join_token.sh manager_join_token.sh

  # We will leave the scripts in our home directory. The sysadmin machine
  # that is facilitating the install process will expect them to be there. The sysadmin
  # will SCP them from this device's home directly to its local working directory
  # and them ship them out to the appropriate nodes in the cluster.
}

#-------------------------------------------------------------------------------

main() {

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

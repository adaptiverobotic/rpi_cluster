#!/bin/bash

# TODO - Find a better way, because this
# is the second time i locked myself out!
# set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

# TODO - MAKE SURE PORT 22 IS OPEN
# OR WE HAVE SOME WAY BACK IN

#-------------------------------------------------------------------------------

declare_variables() {
  readonly ports="assets/ports"
}

#-------------------------------------------------------------------------------

# Configures the firewall for
# a particular provider such
# as docker swarm, kubernetes
configure_firewall() {
  echo "Configuring UFW firewall on each node"
  echo "Sending and running firewall setup script on each node"
  $UTIL scp_ssh_nodes $(pwd)/setup.sh ./setup.sh $(cat $ports)
  echo "Successfully configured UFW firewall on each node"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"
  configure_firewall
}

main "$@"

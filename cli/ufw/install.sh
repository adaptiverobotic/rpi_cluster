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
  :
}

#-------------------------------------------------------------------------------

configure_firewall() {
  echo "Configuring UFW firewall"

  # Get list of dependencies
  ports="assets/ports"

  # SCP setup and password file script to each node
  $UTIL scp_nodes $(pwd)/setup.sh

  # Run setup script on each node
  $UTIL ssh_nodes ./setup.sh $(cat $ports)
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"
  configure_firewall
}

main "$@"

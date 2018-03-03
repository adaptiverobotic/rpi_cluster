#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Placehold function for
# declaring global variables
declare_variables() {
  readonly ip_file=$2; shift
  readonly provider=$2
  readonly hostname_pattern="$COMMON_HOST-$provider"
}

#-------------------------------------------------------------------------------

# Send and run setup
# script on each node
change_hostnames() {
  echo "Changing hostname of each node to take the pattern: $hostname_pattern-xxx"
  $UTIL scp_ssh_specific_nodes $ip_file $(pwd)/setup.sh sudo ./setup.sh $hostname_pattern
  echo "Successfully changed hostname of each node to take the pattern: $hostname_pattern-xxx"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

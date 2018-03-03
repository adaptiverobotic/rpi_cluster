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

# Reverts hostnames to
# original hostnames
revert_hostnames() {

  # TODO - Implement revert hostnames

  echo "Reverting each node's hostname back to it's original hostname"
  $UTIL scp_ssh_specific_nodes $ip_file $(pwd)/setup.sh sudo ./setup.sh revert_hostnames
  $UTIL print_success "SUCCESS:" "Reverted each node's hostname back to it's original hostname"
}

#-------------------------------------------------------------------------------

# Send and run setup
# script on each node
change_hostnames() {
  echo "Changing hostname of each node to take the pattern: $hostname_pattern-xxx"
  $UTIL scp_ssh_specific_nodes $ip_file $(pwd)/setup.sh sudo ./setup.sh $hostname_pattern
  $UTIL print_success "SUCCESS:" "Changed hostname of each node to take the pattern: $hostname_pattern-xxx"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

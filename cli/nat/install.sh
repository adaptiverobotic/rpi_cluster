#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  :
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

main "$@"

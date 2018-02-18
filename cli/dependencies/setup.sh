#!/bin/bash
set -e

#-------------------------------------------------------------------------------

# Global variables
declare_variables() {
  readonly method=$1; shift
  readonly programs=$@
}

#-------------------------------------------------------------------------------

# Display list of programs
display_programs() {
  local message=$1

  echo ""
  echo "$message"
  echo "-----------"
  printf '%s\n' "${programs[@]}"
  echo "-----------"
  echo ""
}

#-------------------------------------------------------------------------------

# Install a list
# of programs
install() {
  display_programs "Installing:"
  sudo apt-get update
  sudo apt-get install $programs -y
  display_programs  "Installed:"
}

#-------------------------------------------------------------------------------

# Uninstall a list
# of programs
uninstall() {
  display_programs "Uninstalling:"
  sudo apt-get --purge autoremove $programs -y
  display_programs "Uninstalled:"
}

#-------------------------------------------------------------------------------

# Uninstalls and
# reinstalls a list
# of programs
reinstall() {
  uninstall $programs
  install $programs
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  $method
}

#-------------------------------------------------------------------------------

main "$@"

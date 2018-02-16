#!/bin/bash
set -e

#-------------------------------------------------------------------------------

# Install a list
# of programs
install() {
  local programs="$@"

  echo "Installing:"
  echo "-----------"
  printf '%s\n' "${programs[@]}"
  echo "-----------"

  sudo apt-get update
  sudo apt-get install "$@" -y

  echo "Installed:"
  echo "----------"
  printf '%s\n' "${programs[@]}"
  echo "----------"
}

#-------------------------------------------------------------------------------

# Uninstall a list
# of programs
uninstall() {
  local programs="$@"

  echo "Uninstalling:"
  echo "-----------"
  printf '%s\n' "${programs[@]}"
  echo "-----------"

  sudo apt-get --purge autoremove "$@" -y

  echo "Uninstalled:"
  echo "----------"
  printf '%s\n' "${programs[@]}"
  echo "----------"
}

#-------------------------------------------------------------------------------

# Uninstalls and
# reinstalls a list
# of programs
reinstall() {
  local programs="$@"

  uninstall $programs
  install $programs
}

#-------------------------------------------------------------------------------

main() {
  echo ""
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"

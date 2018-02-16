#!/bin/bash
set -e

#-------------------------------------------------------------------------------

# Global variables
declare_variables() {
  # TODO - Dynamically get hostname
  # from $SSH_CONNECTION environment variable

  readonly hostname=$1
}

#-------------------------------------------------------------------------------

# Removes all keys associated with the
# hostname of the current ssh client. NOTE -
# Right now we are only permitting one ssh key
# per client. For the scope of this project,
# that's all we need. This way we can avoid
# too many failed authentication issues and worrying
# about excessive ssh flags, or modifying ssh_config
# on nodes to get around these issues.
remove_hostname() {
  # Encompass this in if so we don't error out if the
  # file dos not exist. This is only pertinent to new installs
  echo "Removing all keys associated with $hostname from authorized_keys"

  # Replace old keys associated with sysadmin machine with empty string
  if "sed -i "/${hostname}/d" ~/.ssh/authorized_keys" > /dev/null; then
    echo "Hostname: $hostname removed"
  else
    echo "Hostname: $hostname was not in authorized keys or the file doesn't exist"
  fi
}

#-------------------------------------------------------------------------------

# Main purposely does not
# accept arguments.
main () {
  declare_variables
  remove_hostname
}

main

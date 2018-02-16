#!/bin/bash
set -e

#-------------------------------------------------------------------------------

# Global variables
declare_variables() {

  # TODO - Figure out how to get the dots out of the name
  # or how to remove the shorted hostnames from authorized_keys
  # even though we have the fully qualified. wildcards should do the trick.
  # But that might be destructive....

  # Grab ip from ssh connection. Perform reverse dns lookup.
  # This way we can remove authorized_keys (done by hostname)
  readonly client_ip=$(echo $SSH_CONNECTION | awk '{print $1}')
  readonly client_hostname=$(nslookup $client_ip \
                           | tail -2 \
                           | head -1 \
                           | awk '{print $4}')
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
  if sed -i "/${hostname}/d" $HOME/.ssh/authorized_keys > /dev/null; then
    echo "Hostname: $hostname removed"
  else
    echo "Hostname: $hostname was not in authorized keys or the file doesn't exist"
  fi
}

#-------------------------------------------------------------------------------

# Temporary function for completely
# deleting the authorized_keys file.
# This is an easy way to enforce that
# the nodes (at install time) will only
# have one public key for a given client.
# Later on we can figure out how to do
# maintain one key per host in a less
# destructive way.
delete_authorized_keys() {
    rm -f $HOME/.ssh/authorized_keys
}

#-------------------------------------------------------------------------------

# Main purposely does not
# accept arguments.
main () {
  declare_variables
  # remove_hostname
  delete_authorized_keys
}

#-------------------------------------------------------------------------------

main

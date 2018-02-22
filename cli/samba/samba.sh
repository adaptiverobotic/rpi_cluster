set -e

#-------------------------------------------------------------------------------

# Install samba
install_samba() {

  echo "Updating packages"
  apt-get update -y
  echo "Successfully updated packages"

  echo "Installing samba"
  apt-get install samba -y
  echo "Successfully installed samba"
}

#-------------------------------------------------------------------------------

# Put our conf file
replace_conf() {
  echo "Replacing samba config file"
  rm -f /etc/samba/smb.conf
  cp /smb.conf /etc/samba/smb.conf
  echo "Successfully replaced samba config file"
}

#-------------------------------------------------------------------------------

# Restart samba daemon
restart_samba() {
  echo "Restarting samba daemon"
  /etc/init.d/samba restart
  echo "Successfully restarted samba daemon"
}

#-------------------------------------------------------------------------------

# Make a samba user
create_user() {
  echo "Creating samba user: $COMMON_USER"
  ( echo $COMMON_PASS; echo $COMMON_PASS ) | smbpasswd -a $COMMON_USER
  echo "Successfully created samba user: $COMMON_USER"
}

#-------------------------------------------------------------------------------

main() {
  echo "Entry point script"
  install_samba
  replace_conf
  restart_samba
  create_user
  echo "Done, ready for connection"
}

#-------------------------------------------------------------------------------

main

# Hang so the container
# does not close automatically
# TODO - Find a better way
tail -f /dev/null

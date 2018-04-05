set -e

# TODO - Install NFS, HTTP, FTP along with SMB

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

install_apache() {
  :
}

install_nfs() {
  :
}

install_ftp() {
  :
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

# TODO - Perhaps write a small logging app
# that prints to console when a file is added,
# edited, or removed from the mounted samba directory
tail -f /dev/null

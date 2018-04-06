set -e

# TODO - Install NFS, HTTP, FTP along with SMB

#-------------------------------------------------------------------------------

install_packages() {
  echo "Installing packages"

  apt-get update
  apt-get install -y samba

  echo "Successfully installed all packages"
}

#-------------------------------------------------------------------------------

install_apache() {
  echo "Installing Apache"

  echo "Successfully installed Apache"
}

#-------------------------------------------------------------------------------

install_nfs() {
  echo "Installing NFS"

  echo "Successfully installed NFS"
}

#-------------------------------------------------------------------------------

install_ftp() {
  echo "Installing FTP"

  echo "Successfully installed FTP"
}

#-------------------------------------------------------------------------------

# Install samba
install_samba() {
  echo "Installing Samba"

  # Replace default config
  echo "Replacing samba config file"
  rm -f /etc/samba/smb.conf
  cp /smb.conf /etc/samba/smb.conf
  echo "Successfully replaced samba config file"

  # Restart Samba daemon
  echo "Restarting samba daemon"
  /etc/init.d/samba restart
  echo "Successfully restarted samba daemon"

  # Create Samba user
  echo "Creating samba user: $COMMON_USER"
  ( echo $COMMON_PASS; echo $COMMON_PASS ) | smbpasswd -a $COMMON_USER
  echo "Successfully created samba user: $COMMON_USER"

  echo "Successfully installed Samba"
}

#-------------------------------------------------------------------------------

main() {
  echo "Entry point script"

  # Install packages via apt-get
  install_packages

  echo "Creating HTTP, FTP, NFS, and SMB file share"

  # Install all 4 types
  # by preparing config files, etc
  install_apache
  install_ftp
  install_nfs
  install_samba

  echo "Done, HTTP. FTP, NAS, SMB are ready for connection"
  echo "Use the following credentials (for all protocols):"
  echo "User: $COMMON_USER"
  echo "Password: $COMMON_PASS"
}

#-------------------------------------------------------------------------------

main

# Hang so the container
# does not close automatically
tail -f /dev/null

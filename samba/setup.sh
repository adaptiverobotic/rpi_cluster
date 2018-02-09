# Backup original configuration file
echo "Backing up original Samba config file"
cp /etc/samba/smb.conf ~/
mv ~/smb.conf ~/smb.conf.original

# If something went wrong
if [[ $? -ne 0 ]]; then
  echo "Could not backup /etc/samba/smb.conf"
  exit 1
fi

# Replace it
echo "Creating new config file"
rm -f /etc/samba/smb.conf
cp smb.conf /etc/samba/

# Restart Samba
/etc/init.d/samba restart

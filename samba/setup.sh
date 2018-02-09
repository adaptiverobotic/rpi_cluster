
# Give variables
# meaningful name
user=$1
password=$2

# Backup original configuration file
echo "Backing up original Samba config file"
sudo cp /etc/samba/smb.conf $HOME
sudo mv $HOME/smb.conf $HOME/smb.conf.original

# If something went wrong
if [[ $? -ne 0 ]]; then
  echo "Could not backup /etc/samba/smb.conf"

  # TODO - Perhaps put the old config back?
  exit 1
fi

# Recreate user and give it a password
sudo pdbedit -x -u $user
(echo $password; echo $password) | sudo smbpasswd -a $user

hostname=$(cat /etc/hostname)
drive_name="[home-$hostname]"

echo "drive: $drive_name"

# Modify config file so that we append the hostname
# to the name of the network drive.
sed -i "1s/.*/$drive_name/" smb.conf

# Replace it with custom config file
echo "Creating new config file"
sudo rm -f /etc/samba/smb.conf
sudo cp smb.conf /etc/samba/

# Restart Samba
sudo /etc/init.d/samba restart

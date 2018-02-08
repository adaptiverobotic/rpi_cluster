# Install samba
echo "Installing Samba"
# sudo apt-get update
# sudo apt-get install samba samba-common-bin ufw

# Check exit status
if [ $? -ne 0 ]
then
  echo "Installation not successful"
  exit 1
fi

echo "opening ports required by Samba"
sudo ufw enable

# Open all the required ports
for port in 22 137 138 139 445
do
  sudo ufw allow $port
done

# Check exit status
if [ $? -ne 0 ]
then
  echo "Failed to open ports"
  sudo ufw reset
  exit 1
fi

#-------------------------------------------------------------------------------

# Backup original configuration file
echo "Backing up original Samba config file"
sudo cp /etc/samba/smb.conf ~/
sudo mv ~/smb.conf ~/smb.conf.original

if [ $? -ne 0 ]
then
  echo "Did not backup config file correctly"
  echo "Exiting..."
  exit 1
fi

# Replace it
echo "Creating new config file"
sudo sudo rm -f /etc/samba/smb.conf
sudo cp smb.conf /etc/samba/

# Restart Samba
sudo /etc/init.d/samba restart

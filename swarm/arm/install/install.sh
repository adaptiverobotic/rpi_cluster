# For ssh and scp
user="$1"
ip="$2"
node_num="$3"
setup_dir="setup"

# Set the setup script over to pi via SCP
# ------------------------------------------------------------------------------

# pi@192.168.2.xxx
user_ip=$user@$ip

echo "Establishing scp connection with $user_ip"

# SCP setup files over to pi
scp -r $setup_dir $user_ip:

# Change hostname
# ----------------------------------------------------------------------------
echo "Changing hostname"
ssh $user_ip "sudo ./$setup_dir/change_hostname.sh $user $node_num && exit $?"

# Install Firewall
# ----------------------------------------------------------------------------
echo "Installing Firewall (ufw)"
ssh $user_ip "sudo ./$setup_dir/setup_firewall.sh && exit $?"

# Install Docker
# ----------------------------------------------------------------------------
echo "Installing Docker"
ssh $user_ip "sudo ./$setup_dir/install_docker.sh $user && exit $?"

# Install Portainer
# ----------------------------------------------------------------------------
echo "Installing Portainer"
ssh $user_ip "sudo ./$setup_dir/install_portainer.sh && exit $?"

# Reboot
# ----------------------------------------------------------------------------
echo "Reboot $user_pi"
ssh $user_pi sudo reboot now

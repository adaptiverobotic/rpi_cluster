user="pi"
ip="192.168.2.100"
setup_dir="./"
setup_script="install_samba.sh"

# SCP setup files over to pi
scp -r $setup_dir/ $user@$ip:

# SSH in and run setup script
ssh $user@$ip "cd $setup_dir && sudo ./$setup_script"

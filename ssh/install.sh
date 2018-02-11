#!/bin/bash
set -e

echo "Enabling passwordless ssh"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get common user name
user=$(cat ${DIR}/../assets/user)

# Get list of ips
ips=$(cat ${DIR}/../assets/ips)

# Get this device's hostname
hostname="$(cat /etc/hostname)"

# Directory that contains
# files related to ssh
ssh_dir=$HOME/.ssh/

# Import the expect function so that we
# can automatically insert the password
# when we are prompted at ssh command
expect="${DIR}/../util/expect.sh"
util="/bin/bash ${DIR}/../util/util.sh"

# Create if it does not
# already exist
mkdir -p $ssh_dir

echo "Generating public and private key pair"

# Generate public-private key pairs locally
echo "y" | ssh-keygen -f ${ssh_dir}id_rsa -t rsa -N ''

# Loop through each node
# and delete any old authorized_keys
# that are associate with this device
for ip in $ips
do
  $util my_sshpass ssh $user@$ip "sed -i "/${hostname}/d" ~/.ssh/authorized_keys"
done

echo "Sending public key to each node"

# Loop through ip addresses
for ip in $ips
do
  # Copy the new public key to each node
  $util my_sshpass ssh-copy-id $user@$ip -i ${ssh_dir}id_rsa.pub
done

# Make changes official
ssh-add

echo "Successfully added ssh key to each node"

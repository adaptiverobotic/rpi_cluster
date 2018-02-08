password=$(cat password)

# Give variables
# meaningful names
user=$1
ssh_dir=$HOME/.ssh/

# Re-create directory for SSH keys
mkdir -p $ssh_dir
rm -f ${ssh_dir}id_rsa*

# Generate public-private key pairs locally
ssh-keygen -f ${ssh_dir}id_rsa -t rsa -N ''

# Add public key to
# all other nodes in ip list
for ip in "${@:2}"
do
  # scp ${ssh_dir}id_rsa.pub $user@$ip:
  # ssh $user@$ip "cat ${HOME}/id_rsa.pub >> ${ssh_dir}authorized_keys"

  # TODO - DOES NOT WORK YET!
  echo "ssh-copy-id -i ${ssh_dir}id_rsa.pub $user@$ip"
done

# If anything failed, destroy
# any generated files
if [[ $? -ne 0 ]]; then
  echo "Destroying keys"
  rm -f ${ssh_dir}id_rsa*
fi

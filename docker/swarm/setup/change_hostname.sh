# hostname
etc_hostname="/etc/hostname"
hosts="/etc/hosts"

# For creating host
user="$1"
node_num="$2"

# pi-0
hostname=$user-$node_num

echo "Setting up $hostname"

# Change hostname in hostname /etc/hostname
sudo rm -f $etc_hostname
sudo touch $etc_hostname
echo $hostname >> $etc_hostname

echo "Changed hostname in /etc/hostname to $hostname"

# Change host name in /etc/hosts
cp $hosts $hosts.temp
sed '$ d' $hosts.temp > $hosts
rm -f $hosts.temp
echo "127.0.1.1       $hostname" >> $hosts

echo "Changed hostname in /etc/hosts to $hostname"
echo "Hostname: $(echo | cat /etc/hostname)"

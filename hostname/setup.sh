# hostname
etc_hostname="/etc/hostname"
hosts="/etc/hosts"

# For creating host
user=$1

# Get this node's IP from
# info about it's current
# ssh connection
tmp0=$(hostname -I)
tmp1=($tmp0)
ip=${tmp1[0]}

# Get lat 3 digits from ip
num=$(echo $ip | cut -d . -f 4)

# if ip=192.168.2.100
# hostname=pi-100
hostname=$user-$num

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

# Get MAC address for eth0 interface from ifconfig command and write it out to file
# named address if and only if this device has the eth0 interface
if ifconfig $1; then echo $(ifconfig $1 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}') > 'address'; fi

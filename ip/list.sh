# Get directory of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Give arguments more
# meaningful names
ips="${DIR}/assets/ips"
filters="${DIR}/assets/filters"

echo "Creating list of ip addresses"

# Delete old MAC address list
rm -f $ips

# Create new empty file
touch $ips

# Read in device info in ; delimited list in format hostname;ip_address;mac_address
temp=$(arp -a | sed 's/^\([^ ][^ ]*\) (\([0-9][0-9.]*[0-9]\)) at \([a-fA-F0-9:]*\)[^a-fA-F0-9:].*$/\1;\2;\3/')

# Convert to array
ip_macs=($temp)

# Loop through array of hostname:ip:mac mappings
for i in "${ip_macs[@]}"
do
  # Boolean flag that we use
  # to decide whether or not to
  # add to list of ips
  valid=false

  # Check that MAC matches at least
  # one of the filters in the filter file
  while read line; do
    echo $line
  done <$filters

  # If the current MAC matches,
  # write its corresponding ip
  # out to the ip_address file
  if [[ $valid != true ]]; then
     echo "valid mac: $i"
    echo $i >> $ips
   else
     echo "invalid mac: $i"
   fi
done

# Create path to root ips file
root_ips="${DIR}/../assets/ips"

# Delete old file
# if it exists
rm -f $root_ips

# Copy the ips file to root's
# assets folder for other
# scripts and services to access

cp $ips $root_ips

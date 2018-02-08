# Get directory of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get paths to ips and filters files
ips="${DIR}/../assets/ips"
filters="${DIR}/assets/filters"

echo "Creating list of ip addresses"

# Delete old ip address list
rm -f $ips

# Create new empty list file
touch $ips

# Read in device info as single string in ; delimited list in format hostname;ip_address;mac_address
temp=$(arp -a | sed 's/^\([^ ][^ ]*\) (\([0-9][0-9.]*[0-9]\)) at \([a-fA-F0-9:]*\)[^a-fA-F0-9:].*$/\1;\2;\3/')

# Convert list to array
ip_macs=($temp)

# Loop through array of hostname:ip:mac mappings
for i in "${ip_macs[@]}"
do
  # Boolean flag that we use
  # to decide whether or not to
  # add to list of ips
  valid=false

  # Separate ip and mac
  while IFS=';' read -ra ADDR; do
    ip=${ADDR[1]}
    mac=${ADDR[2]}
  done <<< "$i"

  # Check that MAC matches at least
  # one of the filters in the filter file
  while read line; do
    echo "$mac $line"

    if [[ $mac == $(echo $line)* ]]; then
      valid=true
      break
    fi
  done <$filters

  # If the current MAC matches,
  # write its corresponding ip
  # out to the ip_address file
  if [[ $valid == true ]]; then
    echo $ip >> $ips
   fi
done

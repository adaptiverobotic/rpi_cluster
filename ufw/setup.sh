
# Enable UFW firewall software
sudo ufw enable

# Open all ports
for port in $@
do
  echo "Opening port: $port"
  sudo ufw allow $port

  # If something went wrong
  if [[ $? -ne 0 ]]; then
    echo "Something went wrong, disabling ufw"
    sudo ufw disable
    break
  fi
done

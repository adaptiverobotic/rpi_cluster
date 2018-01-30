# Install and enable ufw
sudo apt-get update
sudo apt-get install ufw
sudo ufw enable

# Check exit status
if [ $? -eq 0 ]
then
  echo "Successfully installed and enabled ufw"
else
  echo "Could not install and enable ufw"
  exit 255
fi

# ------------------------------------------------------------------------------

# Enable default ports
# for interfacing with server
for default in ssh http https
do
  echo "Allowing $default"
  sudo ufw allow $default

  # Check exit status
  if [ $? -eq 0 ]
  then
    echo "SUCCESS: Opened $default"
  else
    echo "FAILURE: Could not open $default"
  fi
done

# Check exit status
if [ $? -eq 0 ]
then
  echo "SUCCESS: Opened ALL default ports"

# Don't continue
else
  echo "FAILURE: Could NOT open all default ports"
  exit 1
fi

# ------------------------------------------------------------------------------

# Ports Docker Swarm uses
# Enable each port
for port in 2377 7946 4789
  do

    # Open the port via ufw
    echo "Opening port $port"
    sudo ufw allow $port/tcp
    sudo ufw allow $port/udp

    # Check exit status
    if [ $? -eq 0 ]
    then
      echo "SUCCESS: Opened port $port"
    else
      echo "FAILURE: Could not open port $port"
    fi

  done

# Check exit status
if [ $? -eq 0 ]
then
  echo "SUCCESS: Opened ALL required ports"

# Don't continue
else
  echo "FAILURE: Could NOT open all required ports"
  exit 2
fi

# ------------------------------------------------------------------------------

# Ports for services
start=8000
stop=50000

# Open lots of ports
sudo ufw allow $start:$stop/tcp
sudo ufw allow $start:$stop/udp

# Check exit status
if [ $? -eq 0 ]
then
  echo "SUCCESS: Opened ALL service ports"
else
  echo "FAILURE: Could NOT open all service ports"
  exit 3
fi

# ------------------------------------------------------------------------------

echo "SUCCESS: Setup sucessful"
exit 0

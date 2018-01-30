ip=$1

# Leave swarm, make a new one
x=$(docker swarm leave --force)
y=$(docker swarm init --advertise-addr $ip)

# Check exit status
if [ $? -ne 0 ]
then
  echo "Failed to init swarm, tokens not generated"
  exit 1
fi

# Get the join-token for workers and managers
echo $(docker swarm join-token worker | grep "docker")
echo $(docker swarm join-token manager | grep "docker")

exit 0

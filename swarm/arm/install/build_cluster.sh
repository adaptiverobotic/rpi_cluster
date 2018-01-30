# For ssh and scp
base_ip="192.168.2."
base=100
user="pi"
leader=0
nodes=3

# Install dependencies and software on all nodes
# ------------------------------------------------------------------------------

# Loop through all ips in range
for ((i=$leader;i<$nodes;i++));
do

  echo "installing $user-$i"

  # Execute script for each node
  ./install.sh $user $base_ip$(($base+$i)) $i
done

# Initialize the Docker Swarm
# ------------------------------------------------------------------------------

# Initialize the swarm and join all nodes
./init_swarm.sh $base_ip $user $base $leader $leader+1 $nodes

# Make sure everything went well
# ------------------------------------------------------------------------------

# Check exit status
if [ $? -eq 0 ]
then
  echo "Everything went well, the cluster is up and running"
  exit 0
else
  echo "Something went wrong initializing the cluster"
  exit 1
fi

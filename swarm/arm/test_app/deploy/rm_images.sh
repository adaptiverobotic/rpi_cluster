while read line; do
  l=($line)
  docker rmi $(docker images --format '{{.Repository}}' | grep ${l[0]})
done <$1

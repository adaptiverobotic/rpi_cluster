while read line; do
  l=($line)
  docker network create -d ${l[1]} ${l[0]}
done <$1

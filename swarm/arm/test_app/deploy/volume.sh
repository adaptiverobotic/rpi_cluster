while read line; do
  l=($line)
  docker volume create -d ${l[1]} ${l[0]}
done <$1

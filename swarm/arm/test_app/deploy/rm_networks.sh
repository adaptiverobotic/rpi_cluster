while read line; do
  l=($line)
  docker network rm ${l[0]}
done <$1

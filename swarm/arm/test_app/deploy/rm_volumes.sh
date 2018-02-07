while read line; do
  l=($line)
  docker volume rm ${l[0]}
done <$1

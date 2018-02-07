while read line; do
  l=($line)
  docker pull ${l[0]}:latest
done <$1

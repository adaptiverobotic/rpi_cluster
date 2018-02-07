while read line; do
  l=($line)
  docker push ${l[0]}:latest
done <$1

while read line; do
  l=($line)
  docker build -t ${l[0]}:latest ../${l[1]}
done <$1

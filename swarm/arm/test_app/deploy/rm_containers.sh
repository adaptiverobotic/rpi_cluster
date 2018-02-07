while read line; do
  l=($line)
  docker rm $(docker stop $(docker ps -a -q --filter ancestor=${l[0]} --format="{{.ID}}"))
done <$1

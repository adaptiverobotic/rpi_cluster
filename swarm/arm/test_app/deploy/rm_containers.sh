while read line; do
  l=($line)
  echo $line
done <$1

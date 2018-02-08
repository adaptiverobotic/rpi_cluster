build() {
  while read line; do
    l=($line)
    docker build -t ${l[0]}:latest ../${l[1]}
  done <$1
}

#-------------------------------------------------------------------------------

network() {
  while read line; do
    l=($line)
    docker network create -d ${l[1]} ${l[0]}
  done <$1
}

#-------------------------------------------------------------------------------

pull() {
  while read line; do
    l=($line)
    docker pull ${l[0]}:latest
  done <$1
}

#-------------------------------------------------------------------------------

push() {
  while read line; do
    l=($line)
    docker push ${l[0]}:latest
  done <$1
}

#-------------------------------------------------------------------------------

secret() {
  echo "Secret"
}

#-------------------------------------------------------------------------------

service() {
  while read line; do

    # Execute docker_service.sh in
    # each directory that is read from file

    # TODO - Make this more portable
    # by reading in fully qualified paths?
    ./../$line/docker_service.sh
  done <$1
}

#-------------------------------------------------------------------------------

volume() {
  while read line; do
    l=($line)
    docker volume create -d ${l[1]} ${l[0]}
  done <$1
}

#-------------------------------------------------------------------------------

"$@"

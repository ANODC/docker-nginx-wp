#!/bin/bash

#####################################
# COLORS BLOCK
RED="\\033[1;31m"
BLUE="\\033[1;34m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
RED="\033[41m\033[1;33m"
NC="\033[0m\n" # No Color

#####################################
# SHOW HELP
show_help() {
  echo "-----------------------------------------------------------------------"
  echo "                      Available commands                              -"
  echo "-----------------------------------------------------------------------"
  echo -e -n "$BLUE"
  echo "   > build - To build the Docker image"
  echo "   > push - To push container"
  echo "   > pull - To pull container"
  echo "   > install - To execute full install at once"
  echo "   > stop - To stop container"
  echo "   > start - To start container"
  echo "   > remove - Remove container"
  echo "   > help - Display this help"
  echo -e -n "$NC"
  echo "-----------------------------------------------------------------------"
}

if [ "$1" == "" ]; then
    show_help
    exit 1
fi

#####################################
# CHECK SUDO

function check_sudo () {
  if [ "$(id -u)" != "0" ]; then
    printf "$RED Sorry, you are not root.$NC"
    exit 1
  fi
}

#####################################
# Load environment variables
export $(cat .env | xargs)

#####################################
# LOG MESSAGE
log() {
  printf "$BLUE > $1 $NORMAL"
}

#####################################
# ERROR MESSAGE
error() {
  printf ""
  printf "$RED >>> ERROR - $1$NORMAL"
}

#####################################
# REMOVE CONTAINER
remove() {
  log "DELETE $CONTAINER_NAME"

  docker stop $CONTAINER_NAME
  docker rm --force $CONTAINER_NAME
  docker rmi --force $CONTAINER_NAME

  docker stop $DOCKER_ID_USER/$CONTAINER_NAME
  docker rm --force $DOCKER_ID_USER/$CONTAINER_NAME
  docker rmi --force $DOCKER_ID_USER/$CONTAINER_NAME
}

#####################################
# STOP CONTAINER
stop() {
  log "STOP $CONTAINER_NAME"

  docker stop $CONTAINER_NAME
}

#####################################
# START CONTAINER
start() {
  log "START $CONTAINER_NAME"

  docker start $CONTAINER_NAME
}

#####################################
# BUILD CONTAINER
build() {
  log "BUILD $CONTAINER_NAME"
  DOCKERFILE=$(pwd)/docker/Dockerfile
  # Build Container
  docker pull $DOCKER_ID_USER/nginx-php:latest
  docker build --rm --no-cache -f $DOCKERFILE -t $CONTAINER_NAME .

  if [ $? -eq 0 ]; then
    log "OK"
  else
    error "FAIL"
    exit 1
  fi
}

#####################################
# PUSH CONTAINER
push() {
  log "PUSH $CONTAINER_NAME"
  docker tag $CONTAINER_NAME $DOCKER_ID_USER/$CONTAINER_NAME:$TAG
  docker push $DOCKER_ID_USER/$CONTAINER_NAME:$TAG
}

#####################################
# PULL CONTAINER
pull() {
  log "PULL $CONTAINER_NAME"
  docker pull $DOCKER_ID_USER/$CONTAINER_NAME:$TAG
}

#####################################
# TEST CONTAINER
test() {
  log "TEST $CONTAINER_NAME"

  docker run -p $PORT_SERVICE:80 \
             --name=$CONTAINER_NAME $CONTAINER_RESTART \
             -dit $DOCKER_ID_USER/$CONTAINER_NAME

  if [ $? -eq 0 ]; then
      printf "$GREEN OK $NC"
  else
      printf "$RED FAIL $NC"
      exit 1
  fi

  log "LOGS $CONTAINER_NAME"

  docker logs $CONTAINER_NAME

  log "COPY TEST FILE $CONTAINER_NAME"

  docker cp ./test/check.php $CONTAINER_NAME:/app/check.php
  docker cp ./test/check.php $CONTAINER_NAME:/app/index.php
  docker cp ./test/info.php $CONTAINER_NAME:/app/info.php
  #docker cp $CONTAINER_NAME:/etc/php7/php.ini ./etc/php-fpm/php.ini
  docker exec -it $CONTAINER_NAME chown nginx:nginx -R /app
  docker exec -it $CONTAINER_NAME ls /app -la

  log "PROCESS LIST $CONTAINER_NAME"

  docker exec -it $CONTAINER_NAME ps -eaf

  log "SERVICE LIST $CONTAINER_NAME"

  docker exec -it $CONTAINER_NAME rc-status --list

  log "PORTS LIST $CONTAINER_NAME"

  docker exec -it $CONTAINER_NAME netstat -l

  log "HTTP TEST $CONTAINER_NAME"

  wget --retry-connrefused --tries=7 --wait=3 --spider http://127.0.0.1:$PORT_SERVICE/check.php -v


  RES_8080=$(curl -sS -v http://localhost:$PORT_SERVICE/check.php 2>&1)
  if grep -q "HTTP/1.1 200 OK" <<< "$RES_8080" ;
  then
    log "TEST1: $CONTAINER_NAME is working!"
  else
    error "$RES_8080"
    error "FAIL"
    docker stop $CONTAINER_NAME
    exit 1
  fi

  log "LOGS $CONTAINER_NAME"

  docker logs $CONTAINER_NAME

  log "STOP $CONTAINER_NAME"
  docker stop $CONTAINER_NAME
}

log "START\n"
$1
log "FINISH\n"


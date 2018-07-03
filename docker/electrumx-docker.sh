#!/bin/bash
set -u

# Copyright (c) 2018 The Bitcore BTX Core Developers
# ElectrumX Server + Bitcore RPC Server Docker Solution
# Script elexctrumx.sh


#
# Define Variables for ElectrumX Server
#
ELECTRUMX_CONTAINER_NAME="electrumx"
DOCKER_REPO="limxtec"
GIT_REPO="limxtec"
ELECTRUMX_SSL_PORT="50002"


#
# Define Variables for BTX RPC Server
#
BTX_CONFIG_PATH="/home/bitcore/.bitcore"
BTX_CONTAINER_NAME="btx-rpc-server"
BTX_DEFAULT_PORT="8555"
BTX_RPC_PORT="8556"
BTX_TOR_PORT="9051"
BTX_WEB="bitcore.cc" # without "https://" and without the last "/" (only HTTPS accepted)
BTX_BOOTSTRAP="bootstrap.tar.gz"


#
# Color definitions
#
RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COL='\033[0m'
BTX_COL='\033[1;35m'


#
# Installation of BTX RPC Server
#
apt-get install wget
wget https://raw.githubusercontent.com/${GIT_REPO}/Bitcore-BTX-RPC-Installer/master/btx-docker.sh -O btx-docker.sh
sed -i "s/^\(DOCKER_REPO=\).*/DOCKER_REPO=$DOCKER_REPO/g" btx-docker.sh
sed -i "s/^\(CONFIG_PATH=\).*/CONFIG_PATH=$BTX_CONFIG_PATH/g" btx-docker.sh
sed -i "s/^\(CONTAINER_NAME=\).*/CONTAINER_NAME=$BTX_CONTAINER_NAME/g" btx-docker.sh
sed -i "s/^\(DEFAULT_PORT=\).*/DEFAULT_PORT=$BTX_DEFAULT_PORT/g" btx-docker.sh
sed -i "s/^\(RPC_PORT=\).*/RPC_PORT=$BTX_RPC_PORT/g" btx-docker.sh
sed -i "s/^\(TOR_PORT=\).*/TOR_PORT=$BTX_TOR_PORT/g" btx-docker.sh
sed -i "s/^\(WEB=\).*/WEB=$BTX_WEB/g" btx-docker.sh
sed -i "s/^\(BOOTSTRAP=\).*/BOOTSTRAP=$BTX_BOOTSTRAP/g" btx-docker.sh
chmod +x ./btx-docker.sh
./btx-docker.sh


#
# Installation of ElectrumX Server
#
printf "\n\nDOCKER SETUP FOR ${BTX_COL}BITCORE (BTX)${NO_COL} ELECTRUMX SERVER\n"


#
# Save needed data from BTX RPC Server to bind with ElectrumX Server
#
BTX_CONFIG="${BTX_CONFIG_PATH}/bitcore.conf"
BTX_RPC_HOST="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${BTX_CONTAINER_NAME})"
BTX_RPC_USER="$(cat ${BTX_CONFIG} | grep rpcuser | cut -d "=" -f 2)"
BTX_RPC_PWD="$(cat ${BTX_CONFIG} | grep rpcpassword | cut -d "=" -f 2)"
BTX_RPC_USER="$(echo $BTX_RPC_USER | tr -d '[:punct:]')"
BTX_RPC_PWD="$(echo $BTX_RPC_PWD | tr -d '[:punct:]')"
BTX_RPC_URL="http://${BTX_RPC_USER}:${BTX_RPC_PWD}@${BTX_RPC_HOST}:8556" #http://user:pass@host:port


#
# Firewall Setup for ElectrumX
#
printf "\nDownload needed Helper-Scripts"
printf "\n------------------------------\n"
wget https://raw.githubusercontent.com/${GIT_REPO}/electrumx/master/docker/check_os.sh -O check_os.sh
chmod +x ./check_os.sh
source ./check_os.sh
wget https://raw.githubusercontent.com/${GIT_REPO}/electrumx/master/docker/firewall_config.sh -O firewall_config.sh
chmod +x ./firewall_config.sh
source ./firewall_config.sh ${ELECTRUMX_SSL_PORT}


#
# Pull docker images and run the docker container
#
printf "\nStart ElectrumX Server Docker Container"
printf "\n---------------------------------------\n"
sudo docker ps | grep ${ELECTRUMX_CONTAINER_NAME} >/dev/null
if [ $? -eq 0 ];then
    printf "${RED}Conflict! The container name \'${ELECTRUMX_CONTAINER_NAME}\' is already in use.${NO_COL}\n"
    printf "\nDo you want to stop the running container to start the new one?\n"
    printf "Enter [Y]es or [N]o and Hit [ENTER]: "
    read STOP

    if [[ $STOP =~ "Y" ]] || [[ $STOP =~ "y" ]]; then
        docker stop ${ELECTRUMX_CONTAINER_NAME}
    else
        printf "\nDocker Setup Result"
        printf "\n----------------------\n"
        printf "${RED}Canceled the Docker Setup without starting ElectrumX Server Docker Container.${NO_COL}\n\n"
        exit 1
    fi
fi
docker rm ${ELECTRUMX_CONTAINER_NAME} >/dev/null
docker pull ${DOCKER_REPO}/electrumx


#
# Start docker ElectrumX Server for Bitcore (BTX) in a docker container
#
# Hint: Only SSL Port 50002 will be open
COIN="Bitcore"
docker run \
  -v ${BTX_CONFIG_PATH}:/data \
  -e DAEMON_URL=${BTX_RPC_URL} \
  -e COIN=${COIN} \
  -p ${ELECTRUMX_SSL_PORT}:${ELECTRUMX_SSL_PORT} \
  --name ${ELECTRUMX_CONTAINER_NAME} \
  -d \
  --rm \
  ${DOCKER_REPO}/electrumx


#
# Add ElectrumX IP Address to Bitcore config file
#
sleep 5
ELX_RPC_HOST="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ELECTRUMX_CONTAINER_NAME})"
#printf "DEBUG ELX_RPC_HOST: ${ELX_RPC_HOST}\n"
sed -i "s|^\(rpcallowip=\).*|rpcallowip=${ELX_RPC_HOST}|g" ${BTX_CONFIG}


#
# Restart bitcored to accept the config change (rpcallowip)
#
printf "\nConnect ElectrumX Server with RPC Server"
printf "\n----------------------------------------\n"
# Wait until Daemon bitcored is running
function is_running {
   running=$(docker exec "$1" supervisorctl status | grep "RUNNING")
   if [ -z "$running" ]; then
      printf "."
      true;
   else
      printf "\n"
      false;
   fi
   return $?;
}
printf "Please wait..."
while is_running ${BTX_CONTAINER_NAME} ; do true; done
docker exec ${BTX_CONTAINER_NAME} supervisorctl restart bitcored
sleep 5
docker exec ${BTX_CONTAINER_NAME} supervisorctl status


#
# Show result and give user instructions
#
sleep 5
clear
printf "\n${BTX_COL}BitCore (BTX}${GREEN} ElectrumX Server + RPC Server Docker Solution${NO_COL}\n"
sudo docker ps | grep ${ELECTRUMX_CONTAINER_NAME} >/dev/null
if [ $? -ne 0 ];then
    printf "${RED}Sorry! Something went wrong. :(${NO_COL}\n"
else
    printf "${GREEN}GREAT! Your ElectrumX Server Docker + RPC Server Docker is running now! :)${NO_COL}\n"
    printf "\nShow your running Docker Container \'${ELECTRUMX_CONTAINER_NAME}\' and \'${BTX_CONTAINER_NAME}\' with ${GREEN}'docker ps'${NO_COL}\n"
    sudo docker ps | grep ${ELECTRUMX_CONTAINER_NAME}
    sudo docker ps | grep ${BTX_CONTAINER_NAME}
    printf "\nJump inside the ElectrumX Server Docker Container with ${GREEN}'docker exec -it ${ELECTRUMX_CONTAINER_NAME} bash'${NO_COL}\n"
     printf "\nJump inside the RPC Server Docker Container with ${GREEN}'docker exec -it ${BTX_CONTAINER_NAME} bash'${NO_COL}\n"
    printf "${GREEN}HAVE FUN!${NO_COL}\n\n"
fi


#
# Check connectivity
#
printf "\nHINT: Show the connectivity with ${GREEN}'docker logs -f ${ELECTRUMX_CONTAINER_NAME}'${NO_COL}\n\n"

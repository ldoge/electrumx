#!/bin/bash
set -x

# Copyright (c) 2018 The Bitsend BSD Core Developers
# ElectrumX Server + Bitsend Docker Solution
# Script elexctrumx.sh


#
# Define Variables for ElectrumX Server
#
ELECTRUMX_CONTAINER_NAME="electrumx"
DOCKER_REPO="dalijolijo"
GIT_REPO="dalijolijo"
ELECTRUMX_SSL_PORT="50002"
ELECTRUMX_RPC_PORT="8000"


#
# Define Variables for BSD Masternode
#
BSD_CONFIG_PATH="/home/bitsend/.bitsend"
BSD_CONFIG="/home/bitsend/.bitsend/bitsend.conf"
BSD_CONTAINER_NAME="bsd-masternode"
BSD_MASTERNODE="0"
BSD_DEFAULT_PORT="8886"
BSD_RPC_PORT="8800"
BSD_TOR_PORT="9051"
BSD_WEB="www.mybitsend.com" # without "https://" and without the last "/" (only HTTPS accepted)
BSD_BOOTSTRAP="bootstrap.tar.gz"


#
# Color definitions
#
RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COL='\033[0m'
BSD_COL='\033[0;34m'


#
# Installation of BSD Masternode
#
apt-get install wget
wget https://raw.githubusercontent.com/${GIT_REPO}/BSD-Masternode-Setup/master/bsd-docker.sh -O bsd-docker.sh
sed -i "s/^\(DOCKER_REPO=\).*/DOCKER_REPO=\"$DOCKER_REPO\"/g" bsd-docker.sh
sed -i "s|^\(CONFIG=\).*|CONFIG=\"$BSD_CONFIG\"|g" bsd-docker.sh
sed -i "s/^\(CONTAINER_NAME=\).*/CONTAINER_NAME=\"$BSD_CONTAINER_NAME\"/g" bsd-docker.sh
sed -i "s/^\(MASTERNODE=\).*/MASTERNODE=\"$BSD_MASTERNODE\"/g" bsd-docker.sh
sed -i "s/^\(DEFAULT_PORT=\).*/DEFAULT_PORT=\"$BSD_DEFAULT_PORT\"/g" bsd-docker.sh
sed -i "s/^\(RPC_PORT=\).*/RPC_PORT=\"$BSD_RPC_PORT\"/g" bsd-docker.sh
sed -i "s/^\(TOR_PORT=\).*/TOR_PORT=\"$BSD_TOR_PORT\"/g" bsd-docker.sh
sed -i "s/^\(WEB=\).*/WEB=\"$BSD_WEB\"/g" bsd-docker.sh
sed -i "s/^\(BOOTSTRAP=\).*/BOOTSTRAP=\"$BSD_BOOTSTRAP\"/g" bsd-docker.sh
chmod +x ./bsd-docker.sh
./bsd-docker.sh
#rm ./bsd-docker.sh

#
# Installation of ElectrumX Server
#
printf "\n\nDOCKER SETUP FOR ${BSD_COL}BITSEND (BSD)${NO_COL} ELECTRUMX SERVER\n"


#
# Save needed data from BSD Masternode to bind with ElectrumX Server
#
BSD_CONFIG="${BSD_CONFIG_PATH}/bitsend.conf"
BSD_RPC_HOST="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${BSD_CONTAINER_NAME})"
BSD_RPC_USER="$(cat ${BSD_CONFIG} | grep rpcuser | cut -d "=" -f 2)"
BSD_RPC_PWD="$(cat ${BSD_CONFIG} | grep rpcpassword | cut -d "=" -f 2)"
BSD_RPC_USER="$(echo $BSD_RPC_USER | tr -d '[:punct:]')"
BSD_RPC_PWD="$(echo $BSD_RPC_PWD | tr -d '[:punct:]')"
BSD_RPC_URL="http://${BSD_RPC_USER}:${BSD_RPC_PWD}@${BSD_RPC_HOST}:${BSD_RPC_PORT}" #http://user:pass@host:port


#
# Firewall Setup for ElectrumX
#
printf "\nDownload needed Helper-Scripts"
printf "\n------------------------------\n"
wget https://raw.githubusercontent.com/${GIT_REPO}/electrumx/master/docker/check_os.sh -O check_os.sh
chmod +x ./check_os.sh
source ./check_os.sh
rm ./check_os.sh
wget https://raw.githubusercontent.com/${GIT_REPO}/electrumx/master/docker/firewall_config.sh -O firewall_config.sh
chmod +x ./firewall_config.sh
source ./firewall_config.sh ${ELECTRUMX_SSL_PORT} ${ELECTRUMX_RPC_PORT}
rm ./firewall_config.sh


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


#
# Start docker ElectrumX Server for Bitsend (BSD) in a docker container
#
# Hint: Only SSL Port 50002 will be open
COIN="Bitsend"
docker run \
  -v ${BSD_CONFIG_PATH}:/data \
  -e DAEMON_URL=${BSD_RPC_URL} \
  -e COIN=${COIN} \
  -p ${ELECTRUMX_SSL_PORT}:${ELECTRUMX_SSL_PORT} \
  -p ${ELECTRUMX_RPC_PORT}:${ELECTRUMX_RPC_PORT} \
  --name ${ELECTRUMX_CONTAINER_NAME} \
  -d \
  --rm \
  ${DOCKER_REPO}/electrumx


#
# Add ElectrumX IP Address to Bitsend config file
#
sleep 5
ELX_RPC_HOST="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ELECTRUMX_CONTAINER_NAME})"
printf "DEBUG ELX_RPC_HOST: ${ELX_RPC_HOST}\n"
sed -i "s|^\(rpcallowip=\).*|rpcallowip=${ELX_RPC_HOST}|g" ${BSD_CONFIG}


#
# Restart bitsendd to accept the config change (rpcallowip)
#
printf "\nConnect ElectrumX Server with Masternode"
printf "\n----------------------------------------\n"
# Wait until Daemon bitsendd is running
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
while is_running ${BSD_CONTAINER_NAME} ; do true; done
docker exec ${BSD_CONTAINER_NAME} supervisorctl restart bitsendd
sleep 5
docker exec ${BSD_CONTAINER_NAME} supervisorctl status


#
# Show result and give user instructions
#
sleep 5
clear
printf "\n${BSD_COL}BitCore (BSD}${GREEN} ElectrumX Server + Masternode Docker Solution${NO_COL}\n"
sudo docker ps | grep ${ELECTRUMX_CONTAINER_NAME} >/dev/null
if [ $? -ne 0 ];then
    printf "${RED}Sorry! Something went wrong. :(${NO_COL}\n"
else
    printf "${GREEN}GREAT! Your ElectrumX Server Docker + Masternode  Docker is running now! :)${NO_COL}\n"
    printf "\nShow your running Docker Container \'${ELECTRUMX_CONTAINER_NAME}\' and \'${BSD_CONTAINER_NAME}\' with ${GREEN}'docker ps'${NO_COL}\n"
    sudo docker ps | grep ${ELECTRUMX_CONTAINER_NAME}
    sudo docker ps | grep ${BSD_CONTAINER_NAME}
    printf "\nJump inside the ElectrumX Server Docker Container with ${GREEN}'docker exec -it ${ELECTRUMX_CONTAINER_NAME} bash'${NO_COL}\n"
     printf "\nJump inside the Masternode Docker Container with ${GREEN}'docker exec -it ${BSD_CONTAINER_NAME} bash'${NO_COL}\n"
    printf "${GREEN}HAVE FUN!${NO_COL}\n\n"
fi


#
# Check connectivity
#
printf "\nHINT: Show the connectivity with ${GREEN}'docker logs -f ${ELECTRUMX_CONTAINER_NAME}'${NO_COL}\n\n"

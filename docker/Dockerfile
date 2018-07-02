# Copyright (c) 2018 The Bitcore BTX Core Developers
# Copyright MIT © Luke Childs <lukechilds123@gmail.com>
#
# This Dockerfile will install all required stuff to run a ElectrumX Server
# ElectrumX Repo : https://github.com/LIMXTEC/electrumx
#
# See BUILD_README.md for further steps.

# Use an official Python runtime as a parent image
FROM python:3.6-alpine3.6
LABEL maintainer="The Bitcore BTX Core Developers"
LABEL version="0.1"

RUN echo '*** ElectrumX Server ***'

# Make ports available to the world outside this container
ENV TCP_PORT=50001
ENV SSL_PORT=50002
# DEPRECATED: Use of 'docker -p <port>:<port>'
#EXPOSE 50001 50002

# Directory where the database will be stored and make it writeable by the electrumx account.
VOLUME ["/data"]
ENV HOME /data
ENV ALLOW_ROOT 1
ENV DB_DIRECTORY /data
WORKDIR /data

# Set SSL environment varibles
ENV SSL_CERTFILE ${DB_DIRECTORY}/electrumx.crt
ENV SSL_KEYFILE ${DB_DIRECTORY}/electrumx.key

# Listen on all interfaces
ENV HOST ""

# Running updates and installing required packages
RUN apk add --no-cache git build-base openssl curl bash vim && \
    apk add --no-cache --repository http://nl.alpinelinux.org/alpine/edge/testing leveldb-dev && \
    pip install aiohttp pylru plyvel

# Install ElectrumX Server
ENV VERSION "1.4"
RUN git clone -b $VERSION https://github.com/limxtec/electrumx.git && \
    cd electrumx && \
    cp ./electrumx_server.py /usr/local/bin/electrumx_server.py && \
    python setup.py install && \
    apk del git build-base && \
    rm -rf /tmp/*

# Change sh to bash
SHELL ["/bin/bash", "-c"]

# Copy start script
COPY ./bin/start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/*
CMD ["start.sh"]

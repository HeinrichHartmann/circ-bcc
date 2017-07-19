#!/bin/bash

cd $(dirname $0)

sudo docker run -it --rm \
     --privileged \
     -v /lib/modules:/lib/modules:ro \
     -v /usr/src:/usr/src:ro \
     -v /etc/localtime:/etc/localtime:ro \
     -v `pwd`:/tree \
     9c2de9c3f585 \
     /tree/bcc.lua

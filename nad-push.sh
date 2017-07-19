#!/bin/bash

export LUA_PATH=/opt/circonus/circ-bcc/lua/?.lua

/opt/circonus/circ-bcc/bcc.lua | while read LINE
do
    date
    echo GOT $LINE
    curl -XPUT localhost:2609/write/bcc -d "$LINE"
done

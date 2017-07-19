#!/bin/bash

export LUA_PATH=/opt/circonus/circ-bcc/lua/?.lua

/opt/circonus/circ-bcc/bpf.lua | while read LINE
do
    date
    echo GOT $LINE
    curl -XPUT localhost:2609/write/bpf -d "$LINE"
done

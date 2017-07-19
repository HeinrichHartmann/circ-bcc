#!/bin/bash

export LUA_PATH=$(pwd)/lua/?.lua

./bcc.lua $@

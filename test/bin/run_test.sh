#!/bin/csh

source config.sh

setenv LUA_PATH "${LUA_PATH};${CORE_DIR}/?.lua"

lua $*

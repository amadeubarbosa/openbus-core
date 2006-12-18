#!/bin/csh

source config.sh

setenv LUA_PATH "${LUA_PATH};${CORE_DIR}/?.lua;${SESSION_SERVICE_DIR}/?.lua"

lua ${SESSION_SERVICE_DIR}/SessionServer.lua

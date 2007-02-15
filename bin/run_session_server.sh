#!/bin/ksh

. ../conf/config

export LUA_PATH="${LUA_PATH};${CORE_DIR}/?.lua;${SESSION_SERVICE_DIR}/?.lua"

${LUA} ${SESSION_SERVICE_DIR}/SessionServer.lua

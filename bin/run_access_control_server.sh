#!/bin/ksh

. ../conf/config

export LUA_PATH="${LUA_PATH};${CORE_DIR}/?.lua;${ACCESS_CONTROL_SERVICE_DIR}/?.lua"

${LUA} ${ACCESS_CONTROL_SERVICE_DIR}/AccessControlServer.lua

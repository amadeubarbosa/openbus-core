#!/bin/csh

source config.sh

setenv LUA_PATH "${LUA_PATH};${CORE_DIR}/?.lua;${ACCESS_CONTROL_SERVICE_DIR}/?.lua"

lua ${ACCESS_CONTROL_SERVICE_DIR}/AccessControlServer.lua

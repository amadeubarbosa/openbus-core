#!/bin/csh

source config.sh

setenv LUA_PATH "${LUA_PATH};${CORE_DIR}/?.lua;${REGISTRY_SERVICE_DIR}/?.lua"

lua ${REGISTRY_SERVICE_DIR}/RegistryServer.lua

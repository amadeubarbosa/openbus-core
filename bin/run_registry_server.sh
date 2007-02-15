#!/bin/ksh

. ../conf/config

export LUA_PATH="${LUA_PATH};${CORE_DIR}/?.lua;${REGISTRY_SERVICE_DIR}/?.lua"

${LUA} ${REGISTRY_SERVICE_DIR}/RegistryServer.lua

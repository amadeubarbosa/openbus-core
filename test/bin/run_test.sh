#!/bin/ksh

PARAMS=$*

. ../../conf/config

LATT_HOME=${OPENBUS_HOME}/libpath/lua/latt

export LUA_PATH="${LUA_PATH};${CORE_DIR}/?.lua"

${LUA} ${LATT_HOME}/ConsoleTestRunner.lua ${PARAMS}

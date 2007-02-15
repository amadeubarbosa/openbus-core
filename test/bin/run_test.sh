#!/bin/ksh

. ../../conf/config

LATT_HOME=${LUA_HOME}/share/lua/5.1/latt

export LUA_PATH="${LUA_PATH};${CORE_DIR}/?.lua"

${LUA} ${LATT_HOME}/ConsoleTestRunner.lua $*

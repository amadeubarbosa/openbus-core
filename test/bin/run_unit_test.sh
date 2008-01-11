#!/bin/sh

PARAMS=$*

. ../../conf/config

LATT_HOME=${LUA_HOME}/share/lua/5.1/latt

${LUA} ${LATT_HOME}/extras/OiLTestRunner.lua ${PARAMS}

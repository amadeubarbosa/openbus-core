#!/bin/ksh

. ${OPENBUS_HOME}/core/conf/config

export LUA_PATH="?.lua;${OPENBUS_HOME}/?.lua;${OPENBUS_HOME}/core/utilities/lua/?.lua;${OPENBUS_HOME}/libpath/lua/5.1/?.lua;${OPENBUS_HOME}/libpath/lua/5.1/?/init.lua"

exec ${OPENBUS_HOME}/core/bin/$TEC_UNAME/servicelauncher runtests.lua $*

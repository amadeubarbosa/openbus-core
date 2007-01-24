#!/bin/csh

setenv LUA_PATH "${LUAUNIT_HOME}/?.lua;${LUA_PATH}"

lua ${LUAUNIT_HOME}/TestRunner.lua $*

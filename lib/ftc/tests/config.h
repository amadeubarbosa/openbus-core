/*
** config.h
*/

#ifndef CONFIG_H_
#define CONFIG_H_

#include <lua.hpp>

const char* SERVER_TMP_PATH;
const char* SERVER_HOST;
unsigned long SERVER_PORT;
const char* LOCAL_TMP_PATH;

void loadConfig() {
  lua_State* L = lua_open();
  if (luaL_dofile(L, "config.lua")) {
    printf("Lua Error: %s", lua_tostring(L, -1));
  } else {
    lua_getglobal(L, "SERVER_TMP_PATH");
    SERVER_TMP_PATH = lua_tostring(L, -1);
    lua_getglobal(L, "SERVER_HOST");
    SERVER_HOST = lua_tostring(L, -1);
    lua_getglobal(L, "SERVER_PORT");
    SERVER_PORT = lua_tointeger(L, -1);
    lua_getglobal(L, "LOCAL_TMP_PATH");
    LOCAL_TMP_PATH = lua_tostring(L, -1);
    lua_pop(L, 3);
  }
}

#endif

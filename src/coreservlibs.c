#include "extralibraries.h"

#include <lua.h>
#include <lauxlib.h>

#ifndef _WIN32
#include <lualdap.h>
#endif
#include "coreservices.h"


const char const* OPENBUS_MAIN = "openbus.core.services.main";

void luapreload_extralibraries(lua_State *L)
{
  /* preload binded C libraries */
#ifndef _WIN32

#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM > 501
  luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
#else
  luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
#endif
  lua_pushcfunction(L,luaopen_lualdap);lua_setfield(L,-2,"lualdap");
  lua_pop(L, 1);  /* pop 'package.preload' table */

#endif
  luapreload_coreservices(L);
}

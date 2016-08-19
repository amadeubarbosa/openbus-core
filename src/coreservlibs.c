#include "extralibraries.h"

#include "lua.h"
#include "lauxlib.h"

#include "luuid.h"
#include "lce.h"
#include "lfs.h"
#ifndef _WIN32
#include "lualdap.h"
#endif
#include "luavararg.h"
#include "luastruct.h"
#include "luasocket.h"
#include "loop.h"
#include "luatuple.h"
#include "luacothread.h"
#include "luaidl.h"
#include "oil.h"
#include "luascs.h"
#include "luaopenbus.h"
#include "coreservices.h"
#include "lsqlite3.h"

LUAMOD_API int luaopen_openbus_util_thread (lua_State *L);

const char const* OPENBUS_MAIN = "openbus.core.services.main";

void luapreload_extralibraries(lua_State *L)
{
  /* preload binded C libraries */
#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM > 501
  luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
#else
  luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
#endif
  lua_pushcfunction(L,luaopen_uuid);lua_setfield(L,-2,"uuid");
  lua_pushcfunction(L,luaopen_lfs);lua_setfield(L,-2,"lfs");
#ifndef _WIN32
  lua_pushcfunction(L,luaopen_lualdap);lua_setfield(L,-2,"lualdap");
#endif
  lua_pushcfunction(L,luaopen_vararg);lua_setfield(L,-2,"vararg");
  lua_pushcfunction(L,luaopen_struct);lua_setfield(L,-2,"struct");
  lua_pushcfunction(L,luaopen_socket_core);lua_setfield(L,-2,"socket.core");
  lua_pushcfunction(L,luaopen_openbus_util_thread);lua_setfield(L,-2,"openbus.util.thread");
  lua_pushcfunction(L,luaopen_lsqlite3);lua_setfield(L,-2,"lsqlite3");
  lua_pop(L, 1);  /* pop 'package.preload' table */
  /* preload other C libraries */
  luapreload_lce(L);
  /* preload script libraries */
  luapreload_loop(L);
  luapreload_luatuple(L);
  luapreload_luacothread(L);
  luapreload_luaidl(L);
  luapreload_oil(L);
  luapreload_luascs(L);
  luapreload_luaopenbus(L);
  luapreload_coreservices(L);
}

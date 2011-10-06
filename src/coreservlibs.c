#include "extralibraries.h"

#include "lua.h"
#include "lauxlib.h"

#include "luuid.h"
#include "lce.h"
#include "lfs.h"
#include "lualdap.h"
#include "luavararg.h"
#include "luastruct.h"
#include "luasocket.h"
#include "loop.h"
#include "looplib.h"
#include "cothread.h"
#include "luaidl.h"
#include "oil.h"
#include "scs.h"
#include "openbus.h"
#include "coreservices.h"

void luapreload_extralibraries(lua_State *L)
{
	/* preload binded C libraries */
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
	lua_pushcfunction(L,luaopen_uuid);lua_setfield(L,-2,"uuid");
	lua_pushcfunction(L,luaopen_lce);lua_setfield(L,-2,"lce");
	lua_pushcfunction(L,luaopen_lfs);lua_setfield(L,-2,"lfs");
	lua_pushcfunction(L,luaopen_lualdap);lua_setfield(L,-2,"lualdap");
	lua_pushcfunction(L,luaopen_vararg);lua_setfield(L,-2,"vararg");
	lua_pushcfunction(L,luaopen_struct);lua_setfield(L,-2,"struct");
	lua_pushcfunction(L,luaopen_socket_core);lua_setfield(L,-2,"socket.core");
	lua_pop(L, 1);  /* pop 'package.preload' table */
	/* preload script libraries */
	luapreload_loop(L);
	luapreload_looplib(L);
	luapreload_cothread(L);
	luapreload_luaidl(L);
	luapreload_oil(L);
	luapreload_scs(L);
	luapreload_openbus(L);
	luapreload_coreservices(L);
}

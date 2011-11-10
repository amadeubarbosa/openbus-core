#include "extralibraries.h"

#include "lua.h"
#include "lauxlib.h"

#include "luuid.h"
#include "lce.h"
#include "lfs.h"
#include "lpw.h"
#include "luavararg.h"
#include "luastruct.h"
#include "luasocket.h"
#include "loop.h"
#include "luatuple.h"
#include "luacoroutine.h"
#include "luacothread.h"
#include "luainspector.h"
#include "luaidl.h"
#include "oil.h"
#include "luascs.h"
#include "luaopenbus.h"
#include "coreadmin.h"

const char const* OPENBUS_MAIN = "openbus.core.admin.main";

void luapreload_extralibraries(lua_State *L)
{
	/* preload binded C libraries */
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
	lua_pushcfunction(L,luaopen_uuid);lua_setfield(L,-2,"uuid");
	lua_pushcfunction(L,luaopen_lce);lua_setfield(L,-2,"lce");
	lua_pushcfunction(L,luaopen_lfs);lua_setfield(L,-2,"lfs");
	lua_pushcfunction(L,luaopen_lpw);lua_setfield(L,-2,"lpw");
	lua_pushcfunction(L,luaopen_vararg);lua_setfield(L,-2,"vararg");
	lua_pushcfunction(L,luaopen_struct);lua_setfield(L,-2,"struct");
	lua_pushcfunction(L,luaopen_socket_core);lua_setfield(L,-2,"socket.core");
	lua_pop(L, 1);  /* pop 'package.preload' table */
	/* preload script libraries */
	luapreload_loop(L);
	luapreload_luatuple(L);
	luapreload_luacoroutine(L);
	luapreload_luacothread(L);
	luapreload_luainspector(L);
	luapreload_luaidl(L);
	luapreload_oil(L);
	luapreload_luascs(L);
	luapreload_luaopenbus(L);
	luapreload_coreadmin(L);
}

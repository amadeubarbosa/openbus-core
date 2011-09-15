#include "extralibraries.h"

#include "lua.h"
#include "lauxlib.h"

#include "luuid.h"
#include "lce.h"
#include "lpw.h"
#include "lfs.h"
#include "lualdap.h"
#include "luasocket.h"
//#include "luaidl.h"
//#include "oil.h"
//#include "scs.h"

void luapreload_extralibraries(lua_State *L)
{
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
	lua_pushcfunction(L,luaopen_uuid);lua_setfield(L,-2,"uuid");
	lua_pushcfunction(L,luaopen_lce);lua_setfield(L,-2,"lce");
	lua_pushcfunction(L,luaopen_lpw);lua_setfield(L,-2,"lpw");
	lua_pushcfunction(L,luaopen_lfs);lua_setfield(L,-2,"lfs");
	lua_pushcfunction(L,luaopen_lualdap);lua_setfield(L,-2,"lualdap");
	lua_pushcfunction(L,luaopen_socket_core);lua_setfield(L,-2,"socket.core");
	lua_pop(L, 1);  /* pop 'package.preload' table */
	//luapreload_luaidl(L);
	//luapreload_oil(L);
	//luapreload_scs(L);
	#include "coreserv.loh"
}

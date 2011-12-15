#include "extralibraries.h"

#include "lua.h"
#include "lauxlib.h"

#include "luuid.h"
#include "lce.h"
#include "lfs.h"
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

/* get password support */
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define LPW_LIBNAME	"lpw"

const char const* OPENBUS_MAIN = "openbus.core.admin.main";
const char const* OPENBUS_PROGNAME = TECMAKE_APPNAME;

static int lpw_getpass(lua_State *L)
{
	const char *prompt = luaL_optstring(L, 1, "");
	char *pass = getpass(prompt);
	if (!pass) {
		lua_pushnil(L);
		lua_pushstring(L, strerror(errno));
		return 2;
	}
	lua_pushstring(L, pass);
	memset(pass, '\0', strlen(pass));
	return 1;
}

static const luaL_Reg lpw_funcs[] = {
	{"getpass", lpw_getpass},
	{NULL, NULL}
};

static int luaopen_lpw(lua_State *L)
{
	luaL_register(L, LPW_LIBNAME, lpw_funcs);
	return 1;
}

void luapreload_extralibraries(lua_State *L)
{
	/* preload binded C libraries */
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
	lua_pushcfunction(L,luaopen_uuid);lua_setfield(L,-2,"uuid");
	lua_pushcfunction(L,luaopen_lce);lua_setfield(L,-2,"lce");
	lua_pushcfunction(L,luaopen_lfs);lua_setfield(L,-2,"lfs");
	lua_pushcfunction(L,luaopen_vararg);lua_setfield(L,-2,"vararg");
	lua_pushcfunction(L,luaopen_struct);lua_setfield(L,-2,"struct");
	lua_pushcfunction(L,luaopen_socket_core);lua_setfield(L,-2,"socket.core");
	lua_pushcfunction(L,luaopen_lpw);lua_setfield(L,-2,LPW_LIBNAME);
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

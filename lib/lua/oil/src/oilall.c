#include <lua.h>
#include <lauxlib.h>

#ifdef COMPAT_51
#include "compat-5.1.h"
#endif

#include "oilbit.h"
#include "../obj/oilall/Linux26/scheduler.h"
#include "../obj/oilall/Linux26/luaidl.h"
#include "../obj/oilall/Linux26/loop.h"
#include "../obj/oilall/Linux26/oil.h"
#include "oilall.h"

OIL_API int luapreload_oilall(lua_State *L) {
  luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 9);

	lua_pushcfunction(L, luaopen_oil_bit);
	lua_setfield(L, -2, "oil.bit");
	lua_pushcfunction(L, luaopen_scheduler);
	lua_setfield(L, -2, "scheduler");
	lua_pushcfunction(L, luaopen_luaidl);
	lua_setfield(L, -2, "luaidl");
	lua_pushcfunction(L, luaopen_luaidl_lex);
	lua_setfield(L, -2, "luaidl.lex");
	lua_pushcfunction(L, luaopen_luaidl_pre);
	lua_setfield(L, -2, "luaidl.pre");
	lua_pushcfunction(L, luaopen_luaidl_sin);
	lua_setfield(L, -2, "luaidl.sin");
	lua_pushcfunction(L, luaopen_loop_base);
	lua_setfield(L, -2, "loop.base");
	lua_pushcfunction(L, luaopen_loop_cached);
	lua_setfield(L, -2, "loop.cached");
	lua_pushcfunction(L, luaopen_loop);
	lua_setfield(L, -2, "loop");
	lua_pushcfunction(L, luaopen_loop_multiple);
	lua_setfield(L, -2, "loop.multiple");
	lua_pushcfunction(L, luaopen_loop_scoped);
	lua_setfield(L, -2, "loop.scoped");
	lua_pushcfunction(L, luaopen_loop_simple);
	lua_setfield(L, -2, "loop.simple");
	lua_pushcfunction(L, luaopen_loop_utils);
	lua_setfield(L, -2, "loop.utils");
	lua_pushcfunction(L, luaopen_loop_collection_MapWithKeyArray);
	lua_setfield(L, -2, "loop.collection.MapWithKeyArray");
	lua_pushcfunction(L, luaopen_loop_collection_ObjectCache);
	lua_setfield(L, -2, "loop.collection.ObjectCache");
	lua_pushcfunction(L, luaopen_loop_collection_OrderedSet);
	lua_setfield(L, -2, "loop.collection.OrderedSet");
	lua_pushcfunction(L, luaopen_loop_collection_PriorityQueue);
	lua_setfield(L, -2, "loop.collection.PriorityQueue");
	lua_pushcfunction(L, luaopen_loop_collection_UnorderedArray);
	lua_setfield(L, -2, "loop.collection.UnorderedArray");
	lua_pushcfunction(L, luaopen_loop_collection_UnorderedArraySet);
	lua_setfield(L, -2, "loop.collection.UnorderedArraySet");
	lua_pushcfunction(L, luaopen_loop_compiler_Conditional);
	lua_setfield(L, -2, "loop.compiler.Conditional");
	lua_pushcfunction(L, luaopen_loop_debug_verbose);
	lua_setfield(L, -2, "loop.debug.verbose");
	lua_pushcfunction(L, luaopen_loop_debug_Viewer);
	lua_setfield(L, -2, "loop.debug.Viewer");
	lua_pushcfunction(L, luaopen_loop_extras_Exception);
	lua_setfield(L, -2, "loop.extras.Exception");
	lua_pushcfunction(L, luaopen_loop_extras_Wrapper);
	lua_setfield(L, -2, "loop.extras.Wrapper");
	lua_pushcfunction(L, luaopen_oil_assert);
	lua_setfield(L, -2, "oil.assert");
	lua_pushcfunction(L, luaopen_oil_cdr);
	lua_setfield(L, -2, "oil.cdr");
	lua_pushcfunction(L, luaopen_oil_Exception);
	lua_setfield(L, -2, "oil.Exception");
	lua_pushcfunction(L, luaopen_oil_giop);
	lua_setfield(L, -2, "oil.giop");
	lua_pushcfunction(L, luaopen_oil_idl);
	lua_setfield(L, -2, "oil.idl");
	lua_pushcfunction(L, luaopen_oil_idl_compiler);
	lua_setfield(L, -2, "oil.idl.compiler");
	lua_pushcfunction(L, luaopen_oil_iiop);
	lua_setfield(L, -2, "oil.iiop");
	lua_pushcfunction(L, luaopen_oil);
	lua_setfield(L, -2, "oil");
	lua_pushcfunction(L, luaopen_oil_invoke);
	lua_setfield(L, -2, "oil.invoke");
	lua_pushcfunction(L, luaopen_oil_ior);
	lua_setfield(L, -2, "oil.ior");
	lua_pushcfunction(L, luaopen_oil_manager);
	lua_setfield(L, -2, "oil.manager");
	lua_pushcfunction(L, luaopen_oil_oo);
	lua_setfield(L, -2, "oil.oo");
	lua_pushcfunction(L, luaopen_oil_orb);
	lua_setfield(L, -2, "oil.orb");
	lua_pushcfunction(L, luaopen_oil_proxy);
	lua_setfield(L, -2, "oil.proxy");
	lua_pushcfunction(L, luaopen_oil_socket);
	lua_setfield(L, -2, "oil.socket");
	lua_pushcfunction(L, luaopen_oil_tcode);
	lua_setfield(L, -2, "oil.tcode");
	lua_pushcfunction(L, luaopen_oil_verbose);
	lua_setfield(L, -2, "oil.verbose");
	lua_pushcfunction(L, luaopen_oil_ir_idl);
	lua_setfield(L, -2, "oil.ir.idl");
	lua_pushcfunction(L, luaopen_oil_ir);
	lua_setfield(L, -2, "oil.ir");

	lua_pop(L, 1);
	return 0;
}

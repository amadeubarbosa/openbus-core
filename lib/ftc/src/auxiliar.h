#ifndef __AUXILIAR__
#define __AUXILIAR__

#include <lua.h>

#ifndef LUAOPEN_API 
#define LUAOPEN_API 
#endif

LUAOPEN_API int luaopen_auxiliar(lua_State *L);

#endif /* __AUXILIAR__ */

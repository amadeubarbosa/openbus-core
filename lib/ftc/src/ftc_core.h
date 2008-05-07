#ifndef __FTC_CORE__
#define __FTC_CORE__

#include <lua.h>

#ifndef LUAOPEN_API 
#define LUAOPEN_API 
#endif

LUAOPEN_API int luaopen_ftc(lua_State *L);
LUAOPEN_API int luaopen_ftc_verbose(lua_State *L);

#endif /* __FTC_CORE__ */

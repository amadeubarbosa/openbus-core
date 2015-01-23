#include "extralibraries.h"

#include <lua.h>
#include <lauxlib.h>

#include "coreadmin.h"


const char const* OPENBUS_MAIN = "openbus.core.admin.main";

void luapreload_extralibraries(lua_State *L)
{
  luapreload_coreadmin(L);
}

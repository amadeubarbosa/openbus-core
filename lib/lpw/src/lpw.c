#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <lua.h>
#include <lauxlib.h>

static int lgetpass(lua_State *L)
{
  const char *prompt = luaL_optstring(L, 1, "");
  char *pass = getpass(prompt);
  if (pass) {
    lua_pushstring(L, pass);
    memset(pass, '\0', strlen(pass));
  }
  else {
    lua_pushnil(L);
    lua_pushstring(L, strerror(errno));
  }
  return 1;
}

static luaL_Reg funcs[] = {
  {"getpass", lgetpass},
  {NULL,      NULL}
};

LUALIB_API int luaopen_lpw(lua_State *L)
{
  luaL_register(L, "lpw", funcs);
  return 1;
}

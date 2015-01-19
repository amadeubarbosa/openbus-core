#include "extralibraries.h"

#include <lua.h>
#include <lauxlib.h>

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM == 501
#include <compat-5.2.h>
#endif

/* get password support */
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#include <windows.h>
#else
#include <unistd.h>
#include <termios.h>
#endif

#include "coreadmin.h"

#define LPW_LIBNAME "lpw"

#if defined(_WIN32)
static void pusherror (lua_State *L) {
  int error = GetLastError();
  char buffer[128];
  if (FormatMessageA(FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM,
      NULL, error, 0, buffer, sizeof(buffer)/sizeof(char), NULL))
    lua_pushstring(L, buffer);
  else
    lua_pushfstring(L, "system error %d\n", error);
}
#endif

static int lpw_getpass(lua_State *L)
{
  char password[10];

  const char *prompt = luaL_optstring(L, 1, "");

#if defined(_WIN32)
  HANDLE hstdin = GetStdHandle(STD_INPUT_HANDLE);
  DWORD omode, nmode;
  
  if (hstdin == INVALID_HANDLE_VALUE || !GetConsoleMode(hstdin, &omode)) {
    lua_pushnil(L);
    pusherror(L);
    return 2;
  }

  nmode = omode;
  nmode &= ~ENABLE_ECHO_INPUT;

  if (!SetConsoleMode(hstdin, nmode)) {
    lua_pushnil(L);
    pusherror(L);
    return 2;
  }
#else
  struct termios oflags, nflags;
  
  /* disabling echo */
  tcgetattr(fileno(stdin), &oflags);
  nflags = oflags;
  nflags.c_lflag &= ~ECHO;
  nflags.c_lflag |= ECHONL;

  if (tcsetattr(fileno(stdin), TCSANOW, &nflags) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, strerror(errno));
    return 2;
  }
#endif

  fputs(prompt, stdout);
  if (fgets(password, sizeof(password), stdin) == NULL) {
    if (ferror(stdin)) {
      return luaL_fileresult(L, 0, "(stdin)");
    } else {
      lua_pushnil(L);
      lua_pushliteral(L, "end of file");
      return 2;
    }
  }

#if defined(_WIN32)
  if (!SetConsoleMode(hstdin, omode)) {
    lua_pushnil(L);
    pusherror(L);
    return 2;
  }
#else
  if (tcsetattr(fileno(stdin), TCSANOW, &oflags) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, strerror(errno));
    return 2;
  }
#endif

  lua_pushlstring(L, password, strlen(password)-1);
  return 1;
}

static const luaL_Reg lpw_funcs[] = {
  {"getpass", lpw_getpass},
  {NULL, NULL}
};

static int luaopen_lpw(lua_State *L)
{
  luaL_newlib(L, lpw_funcs);
  return 1;
}

const char const* OPENBUS_MAIN = "openbus.core.admin.main";

void luapreload_extralibraries(lua_State *L)
{
  /* preload binded C libraries */
#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM > 501
  luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
#else
  luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
#endif
  lua_pushcfunction(L,luaopen_lpw);lua_setfield(L,-2,LPW_LIBNAME);
  lua_pop(L, 1);  /* pop 'package.preload' table */
  luapreload_coreadmin(L);
}

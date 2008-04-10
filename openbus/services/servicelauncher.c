/*
 * OpenBUS: Serviço de controle de acesso
*/


#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define lua_c 

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luasocket.h"
#include "oilall.h"
#include "luuid.h"
#include "lposix.h"
#include "lce.h"
#ifdef ACCESS_CONTROL_SERVICE
  #include "lualdap.h"
#endif

static lua_State *globalL = NULL;

static const char *progname = LUA_FILE;

static void lstop (lua_State *L, lua_Debug *ar) {
  (void)ar;  /* unused arg. */
  lua_sethook(L, NULL, 0, 0);
  luaL_error(L, "interrupted!");
}


static void laction (int i) {
  signal(i, SIG_DFL); /* if another SIGINT happens before lstop,
                              terminate process (default action) */
  lua_sethook(globalL, lstop, LUA_MASKCALL | LUA_MASKRET | LUA_MASKCOUNT, 1);
}


static void l_message (const char *pname, const char *msg) {
  if (pname) fprintf(stderr, "%s: ", pname);
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}


static int report (lua_State *L, int status) {
  if (status && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(progname, msg);
    lua_pop(L, 1);
  }
  return status;
}


static int traceback (lua_State *L) {
  lua_getfield(L, LUA_GLOBALSINDEX, "debug");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_getfield(L, -1, "traceback");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 2);
    return 1;
  }
  lua_pushvalue(L, 1);  /* pass error message */
  lua_pushinteger(L, 2);  /* skip this function and traceback */
  lua_call(L, 2, 1);  /* call debug.traceback */
  return 1;
}


static int docall (lua_State *L, int narg, int clear) {
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
  signal(SIGINT, laction);
  status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base);
  signal(SIGINT, SIG_DFL);
  lua_remove(L, base);  /* remove traceback function */
  /* force a complete garbage collection in case of errors */
  if (status != 0) lua_gc(L, LUA_GCCOLLECT, 0);
  return status;
}



static int dofile (lua_State *L, const char *name) {
  int status = luaL_loadfile(L, name) || docall(L, 0, 1);
  return report(L, status);
}



struct Smain {
  int argc;
  char **argv;
  int status;
};


static int pmain (lua_State *L) {
  struct Smain *s = (struct Smain *)lua_touserdata(L, 1);
  globalL = L;
  lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
  luaL_openlibs(L);  /* open libraries */
  /* Inicialização do OiL */
  // preload the LuaSocket library
  luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
  lua_pushcfunction(L, luaopen_socket_core);
  lua_setfield(L, -2, "socket.core");
  // preload all OiL libraries
  luapreload_oilall(L);
  luaopen_luuid(L);
  luaopen_lposix(L);
#ifdef ACCESS_CONTROL_SERVICE
  luaopen_lualdap(L);
#endif
  luaopen_lce(L);
  lua_gc(L, LUA_GCRESTART, 0);
  dofile(L, progname);
  return 0;
}


int main (int argc, char **argv) {
  int status;
  struct Smain s;
  lua_State *L = lua_open();  /* create state */
  if (L == NULL) {
    l_message(argv[0], "cannot create state: not enough memory");
    return EXIT_FAILURE;
  }
  s.argc = argc;
  s.argv = argv;
  status = lua_cpcall(L, &pmain, &s);
  report(L, status);
  lua_close(L);
  return (status || s.status) ? EXIT_FAILURE : EXIT_SUCCESS;
}


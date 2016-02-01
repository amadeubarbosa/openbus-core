/*
** $Id: lua.c,v 1.206 2012/09/29 20:07:06 roberto Exp $
** Lua stand-alone interpreter
** See Copyright Notice in lua.h
*/


#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "extralibraries.h"

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM == 501
#include "compat-5.2.h"
#include "luacompat52.h"
#endif

#if !defined(LUA_OK)
#define LUA_OK 0
#endif




static lua_State *globalL = NULL;

static const char *progpath = NULL;

static char *logpath = NULL;

static const char *callerchunk =
#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM == 501
" require 'compat52'"
#endif
" local _G = require '_G'"
" local error = _G.error"
" local tostring = _G.tostring"

" local coroutine = require 'coroutine'"
" local newthread = coroutine.create"

" local debug = require 'debug'"
" local traceback = debug.traceback"

" local cothread = require 'cothread'"
" local step = cothread.step"
" local run = cothread.run"

" local log = require 'openbus.util.logger'"

" function cothread.error(thread, errmsg, ...)"
"   errmsg = traceback(thread, tostring(errmsg))"
"   log:unexpected(errmsg)"
"   error(errmsg)"
" end"

" return function(f, ...)"
"   return run(step(newthread(f), ...))"
" end";



static int l_setlogpath (lua_State *L) {
  size_t len;
  const char *path = luaL_checklstring(L, 1, &len);
  if (logpath) luaL_error(L, "log file already defined (path=%s)", logpath);
  ++len;
  logpath = (char *)malloc((len)*sizeof(char));
  strncpy(logpath, path, len);
  return 0;
}


static void l_message (const char *pname, const char *msg) {
  FILE *out = NULL;
  if (logpath) out = fopen(logpath, "a");
  if (out == NULL) out = stderr;
  if (pname) fprintf(out, "%s: ", pname);
  fprintf(out, "%s\n", msg);
  fflush(out);
  if (out != stderr) fclose(out);
}


static int report (lua_State *L, int status) {
  if (status != LUA_OK && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(progpath, msg);
    lua_pop(L, 1);
    /* force a complete garbage collection in case of errors */
    lua_gc(L, LUA_GCCOLLECT, 0);
  }
  return status;
}


/* the next function is called unprotected, so it must avoid errors */
static void finalreport (lua_State *L, int status) {
  if (status != LUA_OK) {
    const char *msg = (lua_type(L, -1) == LUA_TSTRING) ? lua_tostring(L, -1)
                                                       : NULL;
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(progpath, msg);
    lua_pop(L, 1);
  }
}


/*
** By default, Lua uses gmtime/localtime, except when POSIX is available,
** where it uses gmtime_r/localtime_r
*/
#if defined(LUA_USE_GMTIME_R)

#define l_localtime(t,r)  localtime_r(t,r)

#elif !defined(l_gmtime)

#define l_localtime(t,r)    ((void)r, localtime(t))

#endif


static void laction (int i) {
  struct tm tmr, *stm;
  time_t t;
  lua_close(globalL);
  globalL = NULL;
  t = time(NULL);
  stm = l_localtime(&t, &tmr);
  if (stm == NULL) {
    l_message(NULL,
      "--/--/---- --:--:-- [uptime]    process terminated forcefully");
  } else {
    char buff[63];
    strftime(buff, sizeof(buff),
      "%d/%m/%Y %H:%M:%S [uptime]    process terminated forcefully", stm);
    l_message(NULL, buff);
  }
  exit(1);
}


static int traceback (lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  if (msg)
    luaL_traceback(L, L, msg, 1);
  else if (!lua_isnoneornil(L, 1)) {  /* is there an error object? */
    if (!luaL_callmeta(L, 1, "__tostring"))  /* try its 'tostring' metamethod */
      lua_pushliteral(L, "(no error message)");
  }
  return 1;
}


static int docall (lua_State *L, int narg, int nres) {
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
  globalL = L;  /* to be available to 'laction' */
  signal(SIGINT, laction);
  signal(SIGTERM, laction);
  status = lua_pcall(L, narg, nres, base);
  signal(SIGINT, SIG_DFL);
  signal(SIGTERM, SIG_DFL);
  lua_remove(L, base);  /* remove traceback function */
  return status;
}


static int getargs (lua_State *L, char **argv) {
  int narg;
  int i;
  int argc = 0;
  while (argv[argc]) argc++;  /* count total number of arguments */
  narg = argc-1;  /* number of arguments to the script */
  luaL_checkstack(L, narg, "too many arguments to script");
  for (i=1; i < argc; i++) lua_pushstring(L, argv[i]);
  return narg;
}


static int dostring (lua_State *L, const char *s, const char *name) {
  int status = luaL_loadbuffer(L, s, strlen(s), name);
  if (status == LUA_OK) status = docall(L, 0, LUA_MULTRET);
  return status;
}


static int pmain (lua_State *L) {
  char **argv = (char **)lua_touserdata(L, 2);
  int status = LUA_OK;
  /* open standard libraries */
  luaL_checkversion(L);
  lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
  luaL_openlibs(L);  /* open libraries */
  lua_gc(L, LUA_GCRESTART, 0);

  /* export to Lua defined C constants */
  lua_pushliteral(L, OPENBUS_PROGNAME); lua_setglobal(L, "OPENBUS_PROGNAME");
#ifdef OPENBUS_CODEREV
  lua_pushliteral(L, OPENBUS_CODEREV); lua_setglobal(L, "OPENBUS_CODEREV");
#endif
  lua_pushstring(L, OPENBUS_MAIN); lua_setglobal(L, "OPENBUS_MAIN");
  lua_pushcfunction(L, l_setlogpath); lua_setglobal(L, "OPENBUS_SETLOGPATH");
  if (argv[0] && argv[0][0]) {
    progpath = argv[0];
    lua_pushstring(L, progpath); lua_setglobal(L, "OPENBUS_PROGPATH");
    if (argv[1] && argv[1][0] && strcmp(argv[1], "DEBUG") == 0) {
      argv++;
      status = dostring(L,
        "OPENBUS_CODEREV = OPENBUS_CODEREV..'-DEBUG'"
        "table.insert(package.searchers, (table.remove(package.searchers, 1)))",
        "SET_DEBUG");
    }
  }
  
  /* ??? */
  if (status == LUA_OK) {
    /* preload libraries and global variables */
#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM == 501
    luapreload_luacompat52(L);
#endif
    luapreload_extralibraries(L);
    /* execute main module */
    status = dostring(L, callerchunk, "MAIN_THREAD");
    if (status == LUA_OK) {
      lua_getglobal(L, "require");
      lua_pushstring(L, OPENBUS_MAIN);
      status = docall(L, 1, 1);
      if (status == LUA_OK) {
        int narg = getargs(L, argv);  /* collect arguments */
        status = docall(L, narg+1, 1);
        if ( (status == LUA_OK) && lua_isnumber(L, -1) ) return 1;
      }
    }
  }

  report(L, status);
  lua_pushinteger(L, EXIT_FAILURE);
  return 1;
}


int main (int argc, char **argv) {
  int status, result = EXIT_FAILURE;
  lua_State *L = luaL_newstate();  /* create state */
  if (L == NULL) {
    l_message(argv[0], "cannot create Lua state: not enough memory");
    return EXIT_FAILURE;
  }
  /* call 'pmain' in protected mode */
  lua_pushcfunction(L, &pmain);
  lua_pushinteger(L, argc);  /* 1st argument */
  lua_pushlightuserdata(L, argv); /* 2nd argument */
  status = lua_pcall(L, 2, 1, 0);
  if (status == LUA_OK) result = lua_tointeger(L, -1);  /* get result */
  finalreport(L, status);
  lua_close(L);
  if (logpath != NULL) free((void*)logpath);
  return result;
}


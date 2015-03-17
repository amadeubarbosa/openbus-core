#include <signal.h>
#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>

#include <lua.h>
#include <lauxlib.h>

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM == 501
#include "compat-5.2.h"
#endif

static lua_State *globalL = NULL;

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
"   return run(step(newthread(f), ...)) or OPENBUS_EXITCODE"
" end";

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

static void openbuslua_logmessage (const char *pname, const char *msg) {
  if (pname) fprintf(stderr, "%s: ", pname);
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}

static int openbuslua_report (lua_State *L, int status) {
  if (status != LUA_OK && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    openbuslua_logmessage(NULL, msg);
    lua_pop(L, 1);
    /* force a complete garbage collection in case of errors */
    lua_gc(L, LUA_GCCOLLECT, 0);
  }
  return status;
}

static int openbuslua_call (lua_State *L, int narg, int nres) {
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
  globalL = L;  /* to be available to 'laction' */
  signal(SIGINT, laction);
  status = lua_pcall(L, narg, nres, base);
  signal(SIGINT, SIG_DFL);
  lua_remove(L, base);  /* remove traceback function */
  return status;
}

static int openbuslua_dostring (lua_State *L, const char *s, const char *name) {
  int status = luaL_loadbuffer(L, s, strlen(s), name);
  if (status == LUA_OK) status = openbuslua_call(L, 0, LUA_MULTRET);
  return status;
}

static int openbuslua_init (lua_State *L, int interactive, int debugmode) {
  int status = LUA_OK;
  /* open standard libraries */
  luaL_checkversion(L);
  lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
  luaL_openlibs(L);  /* open libraries */
  lua_gc(L, LUA_GCRESTART, 0);

  /* export to Lua defined C constants */
  if (debugmode) {
    lua_pushboolean(L, 1);
    lua_setfield(L, LUA_REGISTRYINDEX, "OPENBUS_DEBUG");
    status = openbuslua_dostring(L,
      " if OPENBUS_CODEREV ~= nil then"
      "   OPENBUS_CODEREV = OPENBUS_CODEREV..'-DEBUG'"
      " end"
      " table.insert(package.searchers, (table.remove(package.searchers, 1)))",
      "SET_DEBUG");
  }
  
  /* open extended libraries */
  if (status == LUA_OK) {
    /* preload libraries and global variables */
#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM == 501
    luapreload_luacompat52(L);
#endif
    /* push main module executor */
    status = openbuslua_dostring(L, callerchunk, "MAIN_THREAD");
  }
  return status;
}


#if defined(_WIN32)

#include <errno.h>
#include <process.h>

static int newthread(void (__cdecl *func) (void *), void *data) {
  uintptr_t res = _beginthread(func, 0, data);
  if (res == -1L) return errno;
	return 0;
}

static const char *geterrmsg(int code) {
  switch (code) {
    case EAGAIN: return "too many threads";
    case EINVAL: return "stack size is incorrect";
    case EACCES: return "insufficient resources";    
  }
	return "unexpected error";
}

static void luathread (void *data)
{
	lua_State *L = (lua_State *)data;
	int status = openbuslua_call(L, 1, 0);
	openbuslua_report(L, status);
}

#else

#include <pthread.h>
#include <errno.h>
#include <string.h>

static int newthread(void *(*func) (void *), void *data) {
	pthread_t thread;
	int res = pthread_create(&thread, NULL, func, data);
	if (res) return errno;
	return 0;
}

static const char *geterrmsg(int code) {
	return strerror(code);
}

static void *luathread (void *data)
{
	lua_State *L = (lua_State *)data;
	int status = openbuslua_call(L, 1, 0);
	openbuslua_report(L, status);
	pthread_exit(NULL);
}

#endif


static void copypreload (lua_State *from, lua_State *to)
{
	/* table is in the stack at index 't' */
#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM > 501
	luaL_getsubtable(from, LUA_REGISTRYINDEX, "_PRELOAD");
	luaL_getsubtable(to, LUA_REGISTRYINDEX, "_PRELOAD");
#else
	luaL_findtable(from, LUA_GLOBALSINDEX, "package.preload", 1);
	luaL_findtable(to, LUA_GLOBALSINDEX, "package.preload", 1);
#endif
	lua_pushnil(from);  /* first key */
	while (lua_next(from, -2) != 0) {
		const char *name = lua_tostring(from, -2);
		lua_CFunction func = lua_tocfunction(from, -1);
		lua_getfield(to, -1, name);
		if (lua_isnil(to, -1) && name != NULL && func != NULL) {
			lua_pushcfunction(to, func);
			lua_setfield(to, -3, name);
		}
		lua_pop(from, 1);  /* pop value and leave key for next iteration */
		lua_pop(to, 1);  /* pop value of '_PRELOAD[modname]' */
	}
	lua_pop(from, 1);  /* pop '_PRELOAD' table */
	lua_pop(to, 1);  /* pop '_PRELOAD' table */
}

static int l_spawn (lua_State *L)
{
	int status = LUA_OK;
	size_t codelen;
	const char *code = luaL_checklstring(L, 1, &codelen);
	lua_State *newL = luaL_newstate();  /* create state */
	if (newL == NULL) luaL_error(L, "not enough memory");
	lua_getfield(L, LUA_REGISTRYINDEX, "OPENBUS_DEBUG");
	status = openbuslua_init(newL, 0, !lua_isnil(L, -1));
	if (status == LUA_OK) {
		copypreload(L, newL);
		status = luaL_loadbuffer(newL, code, codelen, code);
		if (status == LUA_OK) {
			int res = newthread(luathread, newL);
			if (res) {
				const char *errmsg = geterrmsg(errno);
				lua_close(newL);
				luaL_error(L, "unable to start thread (error=%s)", errmsg);
			}
		}
	}
	if (status != LUA_OK && !lua_isnil(newL, -1)) {
		const char *msg = lua_tostring(newL, -1);
		if (msg == NULL) msg = "(error object is not a string)";
		lua_pushstring(L, msg);
		lua_close(newL);
		lua_error(L);
	}
	return 0;
}

static const luaL_Reg funcs[] = {
  {"spawn", l_spawn},
  {NULL, NULL}
};


LUAMOD_API int luaopen_openbus_util_thread (lua_State *L) {
	luaL_newlib(L, funcs);
	return 1;
}

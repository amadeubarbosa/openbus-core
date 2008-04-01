#include <lua.h>
#include <lauxlib.h>
#include "auxiliar.h"

static const unsigned char B0[]={
 27, 76,117, 97, 81,  0,  1,  4,  4,  4,  8,  0, 16,  0,  0,  0, 64, 46, 47, 97,
117,120,105,108,105, 97,114, 46,108,117, 97,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  2,  4, 21,  0,  0,  0,  5,  0,  0,  0, 65, 64,  0,  0, 28, 64,  0,  1,
  5,128,  0,  0,  6,192, 64,  0, 26, 64,  0,  0, 22,128,  2,128,  5,128,  0,  0,
  9,  0,193,129,  5,128,  0,  0,  6, 64, 65,  0, 11,128, 65,  0,133,192,  1,  0,
134,  0, 66,  1,197,128,  0,  0,198, 64,194,  1,156,  0,  0,  1, 28, 64,  0,  0,
 36,  0,  0,  0,  7,128,  2,  0, 30,  0,128,  0, 11,  0,  0,  0,  4,  8,  0,  0,
  0,114,101,113,117,105,114,101,  0,  4,  4,  0,  0,  0,102,116, 99,  0,  4,  4,
  0,  0,  0,111,105,108,  0,  4, 10,  0,  0,  0,105,115,114,117,110,110,105,110,
103,  0,  1,  1,  4,  6,  0,  0,  0,116, 97,115,107,115,  0,  4,  9,  0,  0,  0,
114,101,103,105,115,116,101,114,  0,  4, 10,  0,  0,  0, 99,111,114,111,117,116,
105,110,101,  0,  4,  7,  0,  0,  0, 99,114,101, 97,116,101,  0,  4,  4,  0,  0,
  0,114,117,110,  0,  4,  7,  0,  0,  0,105,110,118,111,107,101,  0,  1,  0,  0,
  0,  0,  0,  0,  0, 13,  0,  0,  0, 23,  0,  0,  0,  0,  1,  7,  7, 21,  0,  0,
  0,197,  0,  0,  0,198, 64,192,  1, 36,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,
  0,  0,  0,128,  0,220, 64,  0,  1,198,128, 64,  1,218, 64,  0,  0, 22,128,  0,
128,197,192,  0,  0,  6,  1, 65,  1,220, 64,  0,  1,197, 64,  1,  0,  1,  1,  1,
  0, 69,129,  1,  0,128,  1,  0,  1, 92,  1,  0,  1,221,  0,  0,  0,222,  0,  0,
  0, 30,  0,128,  0,  7,  0,  0,  0,  4,  4,  0,  0,  0,111,105,108,  0,  4,  5,
  0,  0,  0,109, 97,105,110,  0,  3,  0,  0,  0,  0,  0,  0,240, 63,  4,  6,  0,
  0,  0,101,114,114,111,114,  0,  3,  0,  0,  0,  0,  0,  0,  0, 64,  4,  7,  0,
  0,  0,115,101,108,101, 99,116,  0,  4,  7,  0,  0,  0,117,110,112, 97, 99,107,
  0,  1,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0, 18,  0,  0,  0,  3,  0,  0,
  5, 15,  0,  0,  0, 10,  0,  0,  0, 69,  0,  0,  0, 70, 64,192,  0,132,  0,128,
  0,197,128,  0,  0,  4,  1,  0,  1,220,  0,  0,  1, 92,  0,  0,  0, 34, 64,  0,
  0,  8,  0,  0,  0,  5,  0,  0,  0,  6,192, 64,  0, 11,  0, 65,  0, 28, 64,  0,
  1, 30,  0,128,  0,  5,  0,  0,  0,  4,  4,  0,  0,  0,111,105,108,  0,  4,  6,
  0,  0,  0,112, 99, 97,108,108,  0,  4,  7,  0,  0,  0,117,110,112, 97, 99,107,
  0,  4,  6,  0,  0,  0,116, 97,115,107,115,  0,  4,  5,  0,  0,  0,104, 97,108,
116,  0,  0,  0,  0,  0, 15,  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,
  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,
  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 17,  0,  0,  0, 17,  0,  0,  0, 17,  0,
  0,  0, 17,  0,  0,  0, 18,  0,  0,  0,  0,  0,  0,  0,  3,  0,  0,  0,  4,  0,
  0,  0,114,101,115,  0,  5,  0,  0,  0,102,117,110, 99,  0,  4,  0,  0,  0, 97,
114,103,  0, 21,  0,  0,  0, 15,  0,  0,  0, 15,  0,  0,  0, 18,  0,  0,  0, 18,
  0,  0,  0, 18,  0,  0,  0, 18,  0,  0,  0, 15,  0,  0,  0, 19,  0,  0,  0, 19,
  0,  0,  0, 19,  0,  0,  0, 20,  0,  0,  0, 20,  0,  0,  0, 20,  0,  0,  0, 22,
  0,  0,  0, 22,  0,  0,  0, 22,  0,  0,  0, 22,  0,  0,  0, 22,  0,  0,  0, 22,
  0,  0,  0, 22,  0,  0,  0, 23,  0,  0,  0,  3,  0,  0,  0,  5,  0,  0,  0,102,
117,110, 99,  0,  0,  0,  0,  0, 20,  0,  0,  0,  4,  0,  0,  0, 97,114,103,  0,
  0,  0,  0,  0, 20,  0,  0,  0,  4,  0,  0,  0,114,101,115,  0,  0,  0,  0,  0,
 20,  0,  0,  0,  0,  0,  0,  0, 21,  0,  0,  0,  5,  0,  0,  0,  5,  0,  0,  0,
  5,  0,  0,  0,  7,  0,  0,  0,  7,  0,  0,  0,  7,  0,  0,  0,  7,  0,  0,  0,
  8,  0,  0,  0,  8,  0,  0,  0,  9,  0,  0,  0,  9,  0,  0,  0,  9,  0,  0,  0,
  9,  0,  0,  0,  9,  0,  0,  0,  9,  0,  0,  0,  9,  0,  0,  0,  9,  0,  0,  0,
  9,  0,  0,  0, 23,  0,  0,  0, 13,  0,  0,  0, 23,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,
};

auxiliar int luaopen_auxiliar(lua_State *L) {
	int arg = lua_gettop(L);
	luaL_loadbuffer(L,(const char*)B0,sizeof(B0),"auxiliar.lua");
	lua_insert(L,1);
	lua_call(L,arg,1);
	return 1;
}

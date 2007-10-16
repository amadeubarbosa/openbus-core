#include <lua.h>
#include <lauxlib.h>
#include "auxiliar.h"

static const unsigned char B0[]={
 27, 76,117, 97, 81,  0,  1,  4,  4,  4,  8,  0, 15,  0,  0,  0, 64, 46, 47,111,
112,101,110, 98,117,115, 46,108,117, 97,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  0,  2,  5, 86,  0,  0,  0,  5,  0,  0,  0,  6, 64, 64,  0, 69,192,  0,  0,129,
  0,  1,  0, 92,128,  0,  1,  9, 64,  0,129,  5,  0,  0,  0,  6, 64, 64,  0, 69,
192,  0,  0,129,128,  1,  0, 92,128,  0,  1,  9, 64,128,130,  5,192,  0,  0, 65,
192,  1,  0, 28, 64,  0,  1,  5,192,  1,  0,  6, 64, 66,  0,  6,128, 66,  0,  6,
192, 66,  0,  7,  0,  2,  0,  5,192,  1,  0,  6,  0, 67,  0, 69, 64,  3,  0, 70,
128,195,  0,129,192,  3,  0, 92,128,  0,  1,129,  0,  4,  0, 85,128,128,  0, 28,
 64,  0,  1,  5,192,  1,  0,  6,  0, 67,  0, 69, 64,  3,  0, 70,128,195,  0,129,
192,  3,  0, 92,128,  0,  1,129, 64,  4,  0, 85,128,128,  0, 28, 64,  0,  1,  5,
192,  1,  0,  6,  0, 67,  0, 69, 64,  3,  0, 70,128,195,  0,129,192,  3,  0, 92,
128,  0,  1,129,128,  4,  0, 85,128,128,  0, 28, 64,  0,  1,  5,192,  1,  0,  6,
192, 68,  0, 65,  0,  5,  0, 28, 64,  0,  1,  5,192,  1,  0,  6, 64, 69,  0, 28,
128,128,  0, 69,192,  0,  0,129,192,  5,  0, 92,128,  0,  1, 71,128,  5,  0, 69,
192,  1,  0, 70,  0,198,  0, 75, 64,198,  0,193,128,  6,  0, 92, 64,128,  1, 69,
192,  1,  0, 70,192,198,  0, 70,  0,198,  0, 75, 64,198,  0,193,128,  6,  0, 92,
 64,128,  1,100,  0,  0,  0,  0,  0,  0,  0, 71,  0,  7,  0, 69,192,  1,  0, 70,
192,198,  0, 75, 64,199,  0,197,128,  7,  0,198,192,199,  1,  5,193,  1,  0,  6,
  1, 72,  2,220,  0,  0,  1, 92, 64,  0,  0,100, 64,  0,  0, 71, 64,  8,  0,100,
128,  0,  0, 71,128,  8,  0, 30,  0,128,  0, 35,  0,  0,  0,  4,  8,  0,  0,  0,
112, 97, 99,107, 97,103,101,  0,  4,  7,  0,  0,  0,108,111, 97,100,101,100,  0,
  4, 14,  0,  0,  0,111,105,108, 46, 99,111,109,112,111,110,101,110,116,  0,  4,
  8,  0,  0,  0,114,101,113,117,105,114,101,  0,  4, 23,  0,  0,  0,108,111,111,
112, 46, 99,111,109,112,111,110,101,110,116, 46,119,114, 97,112,112,101,100,  0,
  4,  9,  0,  0,  0,111,105,108, 46,112,111,114,116,  0,  4, 27,  0,  0,  0,108,
111,111,112, 46, 99,111,109,112,111,110,101,110,116, 46,105,110,116,101,114, 99,
101,112,116,101,100,  0,  4,  4,  0,  0,  0,111,105,108,  0,  4, 18,  0,  0,  0,
111,105,108, 99,111,114, 98, 97,105,100,108,115,116,114,105,110,103,  0,  4,  6,
  0,  0,  0, 99,111,114, 98, 97,  0,  4,  4,  0,  0,  0,105,100,108,  0,  4,  7,
  0,  0,  0,115,116,114,105,110,103,  0,  4, 12,  0,  0,  0,108,111, 97,100,105,
100,108,102,105,108,101,  0,  4,  3,  0,  0,  0,111,115,  0,  4,  7,  0,  0,  0,
103,101,116,101,110,118,  0,  4, 14,  0,  0,  0, 67, 79, 82, 66, 65, 95, 73, 68,
 76, 95, 68, 73, 82,  0,  4, 28,  0,  0,  0, 47, 97, 99, 99,101,115,115, 95, 99,
111,110,116,114,111,108, 95,115,101,114,118,105, 99,101, 46,105,100,108,  0,  4,
 22,  0,  0,  0, 47,114,101,103,105,115,116,114,121, 95,115,101,114,118,105, 99,
101, 46,105,100,108,  0,  4, 21,  0,  0,  0, 47,115,101,115,115,105,111,110, 95,
115,101,114,118,105, 99,101, 46,105,100,108,  0,  4,  8,  0,  0,  0,108,111, 97,
100,105,100,108,  0,  4, 42,  0,  0,  0, 32,105,110,116,101,114,102, 97, 99,101,
 32,104,101,108,108,111, 32,123, 32,118,111,105,100, 32,115, 97,121, 95,104,101,
108,108,111, 40, 41, 32, 59, 32,125, 59, 32,  0,  4,  7,  0,  0,  0,103,101,116,
 76, 73, 82,  0,  4, 11,  0,  0,  0, 73, 67,111,109,112,111,110,101,110,116,  0,
  4, 20,  0,  0,  0,115, 99,115, 46, 99,111,114,101, 46, 73, 67,111,109,112,111,
110,101,110,116,  0,  4,  8,  0,  0,  0,118,101,114, 98,111,115,101,  0,  4,  6,
  0,  0,  0,108,101,118,101,108,  0,  3,  0,  0,  0,  0,  0,  0,  0,  0,  4,  6,
  0,  0,  0,116, 97,115,107,115,  0,  4, 12,  0,  0,  0,115,101,110,100,114,101,
113,117,101,115,116,  0,  4,  9,  0,  0,  0,114,101,103,105,115,116,101,114,  0,
  4, 10,  0,  0,  0, 99,111,114,111,117,116,105,110,101,  0,  4,  7,  0,  0,  0,
 99,114,101, 97,116,101,  0,  4,  4,  0,  0,  0,114,117,110,  0,  4,  7,  0,  0,
  0,105,110,118,111,107,101,  0,  4,  5,  0,  0,  0,100,117,109,112,  0,  3,  0,
  0,  0,  0,  0,  0,  0, 30,  0,  0,  0, 36,  0,  0,  0,  1,  4,  0, 11, 20,  0,
  0,  0,  5,  1,  0,  0,  6, 65, 64,  2, 28,129,128,  0, 75,129, 64,  2,192,  1,
  0,  0,  4,  2,  0,  0, 11,194, 64,  4,128,  2,128,  0, 28,130,128,  1,  6,  2,
 65,  4, 92, 65,  0,  2, 74,  1,128,  0,138,129,  0,  0,137,129,  0,131,203,  1,
 66,  2,220,129,  0,  1,137,193,129,131, 98, 65,128,  0,201, 64,129,130, 30,  0,
128,  0,  9,  0,  0,  0,  4,  4,  0,  0,  0,111,105,108,  0,  4, 11,  0,  0,  0,
110,101,119,101,110, 99,111,100,101,114,  0,  4,  4,  0,  0,  0,112,117,116,  0,
  4, 10,  0,  0,  0,108,111,111,107,117,112, 95,105,100,  0,  4,  5,  0,  0,  0,
116,121,112,101,  0,  4, 16,  0,  0,  0,115,101,114,118,105, 99,101, 95, 99,111,
110,116,101,120,116,  0,  4, 11,  0,  0,  0, 99,111,110,116,101,120,116, 95,105,
100,  0,  4, 13,  0,  0,  0, 99,111,110,116,101,120,116, 95,100, 97,116, 97,  0,
  4,  8,  0,  0,  0,103,101,116,100, 97,116, 97,  0,  0,  0,  0,  0, 20,  0,  0,
  0, 31,  0,  0,  0, 31,  0,  0,  0, 31,  0,  0,  0, 32,  0,  0,  0, 32,  0,  0,
  0, 32,  0,  0,  0, 32,  0,  0,  0, 32,  0,  0,  0, 32,  0,  0,  0, 32,  0,  0,
  0, 32,  0,  0,  0, 33,  0,  0,  0, 33,  0,  0,  0, 34,  0,  0,  0, 34,  0,  0,
  0, 34,  0,  0,  0, 34,  0,  0,  0, 35,  0,  0,  0, 35,  0,  0,  0, 36,  0,  0,
  0,  5,  0,  0,  0, 11,  0,  0,  0, 99,114,101,100,101,110,116,105, 97,108,  0,
  0,  0,  0,  0, 19,  0,  0,  0, 15,  0,  0,  0, 99,114,101,100,101,110,116,105,
 97,108, 84,121,112,101,  0,  0,  0,  0,  0, 19,  0,  0,  0, 10,  0,  0,  0, 99,
111,110,116,101,120,116, 73, 68,  0,  0,  0,  0,  0, 19,  0,  0,  0,  8,  0,  0,
  0,114,101,113,117,101,115,116,  0,  0,  0,  0,  0, 19,  0,  0,  0,  8,  0,  0,
  0,101,110, 99,111,100,101,114,  0,  3,  0,  0,  0, 19,  0,  0,  0,  1,  0,  0,
  0,  4,  0,  0,  0,108,105,114,  0,  0,  0,  0,  0, 41,  0,  0,  0, 51,  0,  0,
  0,  0,  1,  7,  7, 21,  0,  0,  0,197,  0,  0,  0,198, 64,192,  1, 36,  1,  0,
  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  0,128,  0,220, 64,  0,  1,198,128, 64,
  1,218, 64,  0,  0, 22,128,  0,128,197,192,  0,  0,  6,  1, 65,  1,220, 64,  0,
  1,197, 64,  1,  0,  1,  1,  1,  0, 69,129,  1,  0,128,  1,  0,  1, 92,  1,  0,
  1,221,  0,  0,  0,222,  0,  0,  0, 30,  0,128,  0,  7,  0,  0,  0,  4,  4,  0,
  0,  0,111,105,108,  0,  4,  5,  0,  0,  0,109, 97,105,110,  0,  3,  0,  0,  0,
  0,  0,  0,240, 63,  4,  6,  0,  0,  0,101,114,114,111,114,  0,  3,  0,  0,  0,
  0,  0,  0,  0, 64,  4,  7,  0,  0,  0,115,101,108,101, 99,116,  0,  4,  7,  0,
  0,  0,117,110,112, 97, 99,107,  0,  1,  0,  0,  0,  0,  0,  0,  0, 43,  0,  0,
  0, 46,  0,  0,  0,  3,  0,  0,  5, 15,  0,  0,  0, 10,  0,  0,  0, 69,  0,  0,
  0, 70, 64,192,  0,132,  0,128,  0,197,128,  0,  0,  4,  1,  0,  1,220,  0,  0,
  1, 92,  0,  0,  0, 34, 64,  0,  0,  8,  0,  0,  0,  5,  0,  0,  0,  6,192, 64,
  0, 11,  0, 65,  0, 28, 64,  0,  1, 30,  0,128,  0,  5,  0,  0,  0,  4,  4,  0,
  0,  0,111,105,108,  0,  4,  6,  0,  0,  0,112, 99, 97,108,108,  0,  4,  7,  0,
  0,  0,117,110,112, 97, 99,107,  0,  4,  6,  0,  0,  0,116, 97,115,107,115,  0,
  4,  5,  0,  0,  0,104, 97,108,116,  0,  0,  0,  0,  0, 15,  0,  0,  0, 44,  0,
  0,  0, 44,  0,  0,  0, 44,  0,  0,  0, 44,  0,  0,  0, 44,  0,  0,  0, 44,  0,
  0,  0, 44,  0,  0,  0, 44,  0,  0,  0, 44,  0,  0,  0, 44,  0,  0,  0, 45,  0,
  0,  0, 45,  0,  0,  0, 45,  0,  0,  0, 45,  0,  0,  0, 46,  0,  0,  0,  0,  0,
  0,  0,  3,  0,  0,  0,  4,  0,  0,  0,114,101,115,  0,  5,  0,  0,  0,102,117,
110, 99,  0,  4,  0,  0,  0, 97,114,103,  0, 21,  0,  0,  0, 43,  0,  0,  0, 43,
  0,  0,  0, 46,  0,  0,  0, 46,  0,  0,  0, 46,  0,  0,  0, 46,  0,  0,  0, 43,
  0,  0,  0, 47,  0,  0,  0, 47,  0,  0,  0, 47,  0,  0,  0, 48,  0,  0,  0, 48,
  0,  0,  0, 48,  0,  0,  0, 50,  0,  0,  0, 50,  0,  0,  0, 50,  0,  0,  0, 50,
  0,  0,  0, 50,  0,  0,  0, 50,  0,  0,  0, 50,  0,  0,  0, 51,  0,  0,  0,  3,
  0,  0,  0,  5,  0,  0,  0,102,117,110, 99,  0,  0,  0,  0,  0, 20,  0,  0,  0,
  4,  0,  0,  0, 97,114,103,  0,  0,  0,  0,  0, 20,  0,  0,  0,  4,  0,  0,  0,
114,101,115,  0,  0,  0,  0,  0, 20,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
 54,  0,  0,  0, 58,  0,  0,  0,  0,  1,  0,  9, 16,  0,  0,  0, 69,  0,  0,  0,
129, 64,  0,  0,192,  0,  0,  0, 92, 64,128,  1, 69,128,  0,  0,128,  0,  0,  0,
 92,  0,  1,  1, 22,192,  0,128,133,  1,  0,  0,192,  1,  0,  2,  0,  2,128,  2,
156, 65,128,  1, 97,128,  0,  0, 22, 64,254,127, 30,  0,  0,  1, 30,  0,128,  0,
  3,  0,  0,  0,  4,  6,  0,  0,  0,112,114,105,110,116,  0,  4, 14,  0,  0,  0,
 35, 35, 32, 68, 85, 77, 80, 73, 78, 71, 32, 45, 62,  0,  4,  6,  0,  0,  0,112,
 97,105,114,115,  0,  0,  0,  0,  0, 16,  0,  0,  0, 55,  0,  0,  0, 55,  0,  0,
  0, 55,  0,  0,  0, 55,  0,  0,  0, 56,  0,  0,  0, 56,  0,  0,  0, 56,  0,  0,
  0, 56,  0,  0,  0, 56,  0,  0,  0, 56,  0,  0,  0, 56,  0,  0,  0, 56,  0,  0,
  0, 56,  0,  0,  0, 56,  0,  0,  0, 57,  0,  0,  0, 58,  0,  0,  0,  6,  0,  0,
  0,  4,  0,  0,  0,116, 97, 98,  0,  0,  0,  0,  0, 15,  0,  0,  0, 16,  0,  0,
  0, 40,102,111,114, 32,103,101,110,101,114, 97,116,111,114, 41,  0,  7,  0,  0,
  0, 14,  0,  0,  0, 12,  0,  0,  0, 40,102,111,114, 32,115,116, 97,116,101, 41,
  0,  7,  0,  0,  0, 14,  0,  0,  0, 14,  0,  0,  0, 40,102,111,114, 32, 99,111,
110,116,114,111,108, 41,  0,  7,  0,  0,  0, 14,  0,  0,  0,  2,  0,  0,  0,107,
  0,  8,  0,  0,  0, 12,  0,  0,  0,  2,  0,  0,  0,118,  0,  8,  0,  0,  0, 12,
  0,  0,  0,  0,  0,  0,  0, 86,  0,  0,  0,  5,  0,  0,  0,  5,  0,  0,  0,  5,
  0,  0,  0,  5,  0,  0,  0,  5,  0,  0,  0,  5,  0,  0,  0,  6,  0,  0,  0,  6,
  0,  0,  0,  6,  0,  0,  0,  6,  0,  0,  0,  6,  0,  0,  0,  6,  0,  0,  0, 10,
  0,  0,  0, 10,  0,  0,  0, 10,  0,  0,  0, 12,  0,  0,  0, 12,  0,  0,  0, 12,
  0,  0,  0, 12,  0,  0,  0, 12,  0,  0,  0, 14,  0,  0,  0, 14,  0,  0,  0, 14,
  0,  0,  0, 14,  0,  0,  0, 14,  0,  0,  0, 14,  0,  0,  0, 14,  0,  0,  0, 14,
  0,  0,  0, 14,  0,  0,  0, 15,  0,  0,  0, 15,  0,  0,  0, 15,  0,  0,  0, 15,
  0,  0,  0, 15,  0,  0,  0, 15,  0,  0,  0, 15,  0,  0,  0, 15,  0,  0,  0, 15,
  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,
  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 16,  0,  0,  0, 19,
  0,  0,  0, 19,  0,  0,  0, 19,  0,  0,  0, 19,  0,  0,  0, 21,  0,  0,  0, 21,
  0,  0,  0, 21,  0,  0,  0, 23,  0,  0,  0, 23,  0,  0,  0, 23,  0,  0,  0, 23,
  0,  0,  0, 25,  0,  0,  0, 25,  0,  0,  0, 25,  0,  0,  0, 25,  0,  0,  0, 25,
  0,  0,  0, 26,  0,  0,  0, 26,  0,  0,  0, 26,  0,  0,  0, 26,  0,  0,  0, 26,
  0,  0,  0, 26,  0,  0,  0, 36,  0,  0,  0, 36,  0,  0,  0, 30,  0,  0,  0, 38,
  0,  0,  0, 38,  0,  0,  0, 38,  0,  0,  0, 38,  0,  0,  0, 38,  0,  0,  0, 38,
  0,  0,  0, 38,  0,  0,  0, 38,  0,  0,  0, 38,  0,  0,  0, 51,  0,  0,  0, 41,
  0,  0,  0, 58,  0,  0,  0, 54,  0,  0,  0, 58,  0,  0,  0,  1,  0,  0,  0,  4,
  0,  0,  0,108,105,114,  0, 54,  0,  0,  0, 85,  0,  0,  0,  0,  0,  0,  0,
};

auxiliar int luaopen_openbus(lua_State *L) {
	int arg = lua_gettop(L);
	luaL_loadbuffer(L,(const char*)B0,sizeof(B0),"openbus.lua");
	lua_insert(L,1);
	lua_call(L,arg,1);
	return 1;
}

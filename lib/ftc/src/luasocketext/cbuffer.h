/*
* cbuffer.h
*/

#ifndef CBUFFER_H_
#define CBUFFER_H_

typedef struct lua_State Lua_State;

int cbuffer_open( Lua_State *L );
int cbuffer_receive( Lua_State* L );
int cbuffer_send( Lua_State* L );
int cbuffer_writeToFile( Lua_State* L );
int cbuffer_readFromFile( Lua_State* L );

#endif


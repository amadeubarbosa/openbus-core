/*
* cbuffer.c
*/

#include "cbuffer.h"

#include <lua.h>
#include <lauxlib.h>
#include "string.h"
#include "socket.h"
#include "tcp.h"

/*
* object:receive() interface
* without pattern support
*/
int cbuffer_receive( Lua_State* L )
{
  char* data ;
  size_t nbytes ;
  size_t got ;
  size_t dataPosition = 0 ;
#if VERBOSE
  printf( "\n\t[receive() COMECO]\n" ) ;
#endif
  p_tcp tcp = (p_tcp) lua_touserdata( L, 1 ) ;
#if VERBOSE
  printf( "\t\t[P_TCP(%p)]\n", tcp ) ;
  printf( "\t\t[Socket ID: %d]\n", tcp->sock ) ;
#endif
  nbytes = lua_tointeger( L, 2 ) ;
#if VERBOSE
  printf( "\t\t[Num. of bytes to read: %d]\n", nbytes ) ;
#endif
  data = (char*) lua_topointer( L, 3 ) ;
#if VERBOSE
  printf( "\t\t[Data buffer recovered(%p)]\n", data ) ;
#endif
  dataPosition = lua_tointeger( L, 4 ) ;
#if VERBOSE
  printf( "\t\t[Data position: %d]\n", dataPosition ) ;
#endif
  lua_pop( L, 3 ) ;
  int ret = socket_recv( &tcp->sock, (data + dataPosition), nbytes, &got, &tcp->tm ) ;
#if VERBOSE
  printf( "\t\t[socket_recv returns %d]\n", ret ) ;
#endif
  if ( ret == IO_DONE ) {
  #if VERBOSE
    printf( "\t\t[GOT %d bytes]\n", got ) ;
    printf( "\t\t[socket_recv return value: %d]\n\t\t[Byte Sequence:", ret ) ;
  #if VERBOSE2
    int x ;
    char* ptr = data + dataPosition ;
    for ( x = 0; x < (int) got; x++ ) {
      printf( " [%d]:%c", x, ptr[ x ] ) ;
    }
  #endif
    printf( "]" ) ;
  #endif
    if ( got == nbytes ) {
      lua_pushlightuserdata( L, data ) ;
      lua_pushnil( L ) ;
      lua_pushnumber( L, got ) ;
    } else {
      lua_pushnil( L ) ;
      lua_pushstring( L, "timeout" ) ;
      lua_pushnumber( L, got ) ;
    }
  } else if ( ret == IO_TIMEOUT ) {
  #if VERBOSE
    printf( "\t\t[TIMEOUT GOT %d bytes]", got ) ;
  #endif
    lua_pushnil( L ) ;
    lua_pushstring( L, "timeout" ) ;
    lua_pushnumber( L, got ) ;
  } else if ( ret == IO_CLOSED ) {
  #if VERBOSE
    printf( "\t\t[CLOSED GOT %d bytes]", got ) ;
  #endif
    lua_pushnil( L ) ;
    lua_pushstring( L, "closed" ) ;
    lua_pushnumber( L, got ) ;
  } else if ( ret == IO_UNKNOWN ) {
  #if VERBOSE
    printf( "\t\t[UNKNOWN ERROR GOT %d bytes]", got ) ;
  #endif
    lua_pushnil( L ) ;
    lua_pushstring( L, "timeout" ) ;
    lua_pushnumber( L, got ) ;
  }
  #if VERBOSE
    printf( "\n\t[receive() FIM]\n\n" ) ;
  #endif
  return 3 ;
}

/*
* object:send() interface
* without pattern support
*/
int cbuffer_send( Lua_State* L )
{
  size_t nbytes ;
#if VERBOSE
  printf( "\n\t[writeToFile() COMECO]\n" ) ;
#endif
  p_tcp tcp = (p_tcp) lua_touserdata( L, 1 ) ;
#if VERBOSE
  printf( "\t\t[P_TCP(%p)]\n", tcp ) ;
  printf( "\t\t[Socket ID: %d]\n", tcp->sock ) ;
#endif
  
  nbytes = lua_tointeger( L, 3 ) ;
#if VERBOSE
  printf( "\t\t[Num. of bytes to write: %d]\n", nbytes ) ;
#endif
  const void * data = (const void*) lua_topointer( L, 4 ) ;
#if VERBOSE
  printf( "\t\t[Data buffer recovered(%p)]\n", data ) ;
#endif

  size_t got=0 ;
  
  int ret = socket_send( &tcp->sock , data, nbytes, &got, &tcp->tm);

#if VERBOSE
  printf( "\t\t[Num. of bytes written: %d]\n", ret) ;
#endif
  if ( ret == IO_DONE ) {
      lua_pushnumber( L, got ) ;
	  return 1;
  }
  
  lua_pushnil(L);
  
  if ( ret == IO_CLOSED )
  {
  #if VERBOSE
    printf( "\t\t[TIMEOUT GOT %d bytes]", got ) ;
  #endif
    lua_pushstring( L, "closed" ) ;
  }
  else
  {
  #if VERBOSE
    printf( "\t\t[SEND ERROR GOT %d bytes]", got ) ;
  #endif
	lua_pushstring( L , socket_strerror(ret));
  }

  lua_pushnumber( L, got ) ;
    
  return 3 ;
}	

/*
* object:writeToFile() interface
* without pattern support
*/
int cbuffer_writeToFile( Lua_State* L )
{
  size_t nbytes ;
#if VERBOSE
  printf( "\n\t[writeToFile() COMECO]\n" ) ;
#endif
  p_tcp tcp = (p_tcp) lua_touserdata( L, 1 ) ;
#if VERBOSE
  printf( "\t\t[P_TCP(%p)]\n", tcp ) ;
  printf( "\t\t[Socket ID: %d]\n", tcp->sock ) ;
#endif

  FILE* fd = (FILE*) lua_topointer( L, 2 ) ;
#if VERBOSE
  printf( "\t\t[FILE pointer recovered(%p)]\n", fd) ;
#endif
  
  nbytes = lua_tointeger( L, 3 ) ;
#if VERBOSE
  printf( "\t\t[Num. of bytes to write: %d]\n", nbytes ) ;
#endif
  const void * data = (const void*) lua_topointer( L, 4 ) ;
#if VERBOSE
  printf( "\t\t[Data buffer recovered(%p)]\n", data ) ;
#endif

  size_t ret = fwrite(data, nbytes, 1, fd); 
#if VERBOSE
  printf( "\t\t[Num. of bytes written: %d]\n", ret) ;
#endif
  if ( ret == 1 ) {
      lua_pushnumber( L, ret ) ;
	  return 1;
  } 
  
  lua_pushnil( L ) ;
  lua_pushstring( L, strerror(ferror(fd)) ) ;
  lua_pushnumber( L, ret ) ;
    
  return 3 ;
}

/*
* object:send() interface
* without pattern support
*/
int cbuffer_readFromFile( Lua_State* L )
{
  char* data ;
  size_t nbytes ;
  size_t dataPosition = 0 ;
#if VERBOSE
  printf( "\n\t[readFromFile() COMECO]\n" ) ;
#endif
  p_tcp tcp = (p_tcp) lua_touserdata( L, 1 ) ;
#if VERBOSE
  printf( "\t\t[P_TCP(%p)]\n", tcp ) ;
  printf( "\t\t[Socket ID: %d]\n", tcp->sock ) ;
#endif

  FILE* fd = (FILE*) lua_topointer( L, 2 ) ;
#if VERBOSE
  printf( "\t\t[FILE pointer recovered(%p)]\n", fd) ;
#endif

  nbytes = lua_tointeger( L, 2 ) ;
#if VERBOSE
  printf( "\t\t[Num. of bytes to read: %d]\n", nbytes ) ;
#endif

  data = (char*) lua_topointer( L, 3 ) ;
#if VERBOSE
  printf( "\t\t[Data buffer recovered(%p)]\n", data ) ;
#endif

  dataPosition = lua_tointeger( L, 4 ) ;
#if VERBOSE
  printf( "\t\t[Data position: %d]\n", dataPosition ) ;
#endif
  lua_pop( L, 3 ) ;
  size_t ret = fread((void *)data, nbytes, 1, fd );
#if VERBOSE
  printf( "\t\t[socket_recv returns %d]\n", ret ) ;
#endif
  if ( ret ==  1 ) {
  #if VERBOSE
    printf( "\t\t[GOT %d bytes]\n", nbytes ) ;
    printf( "\t\t[socket_recv return value: %d]\n\t\t[Byte Sequence:", ret ) ;
  #endif
    lua_pushlightuserdata( L, data ) ;
    lua_pushnumber( L, nbytes) ;
#if VERBOSE
	printf( "\n\t[readFromFile() FIM]\n" ) ;
#endif
  }

  lua_pushnil( L ) ;
  lua_pushstring( L, strerror(ferror(fd)) ) ;
  lua_pushnumber( L, ret ) ;
  return 3 ;
}	

int cbuffer_open(Lua_State *L) {
  lua_register(L, "receiveC", cbuffer_receive);
  lua_register(L, "sendC", cbuffer_send);
  lua_register(L, "writeToFile", cbuffer_writeToFile);
  lua_register(L, "readFromFile", cbuffer_readFromFile);
  return 0;
}


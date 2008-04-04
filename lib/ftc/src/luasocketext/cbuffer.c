/*
* cbuffer.c
*/

#include "cbuffer.h"

#include <lua.h>
#include <lauxlib.h>
#include <socket.h>
#include <tcp.h>

#define STEPSIZE 8192
static int sendraw(p_buffer buf, const char *data, size_t count, size_t *sent) {
    p_io io = buf->io;
    p_timeout tm = buf->tm;
    size_t total = 0;
    int err = IO_DONE;
    while (total < count && err == IO_DONE) {
        size_t done;
        size_t step = (count-total <= STEPSIZE)? count-total: STEPSIZE;
        err = io->send(io->ctx, data+total, step, &done, tm);
        total += done;
    }
    *sent = total;
    buf->sent += total;
    return err;
}

/*
* object:send() interface
*/
int cbuffer_send( Lua_State* L )
{
  char* data ;
  size_t nbytes = 0;
  size_t sent = 0;
  int err = IO_DONE;
#if VERBOSE
  printf( "\n\t[send() COMECO]\n" ) ;
#endif
  t_tcp* p_tcp = (t_tcp*) lua_touserdata( L, 1 ) ;
#if VERBOSE
  printf( "\t\t[P_TCP(%p)]\n", p_tcp ) ;
  printf( "\t\t[Socket ID: %d]\n", p_tcp->sock ) ;
#endif
  nbytes = lua_tointeger( L, 2 ) ;
#if VERBOSE
  printf( "\t\t[Num. of bytes to send: %d]\n", nbytes ) ;
#endif
  data = (char*) lua_topointer( L, 3 ) ;
#if VERBOSE
  printf( "\t\t[Data buffer recovered(%p)]\n", data ) ;
#endif
/*  lua_pop( L, 3 ) ;*/
  long start = (long) luaL_optnumber(L, 4, 1);
#if VERBOSE
  printf( "\t\t[START position: %ld]\n", start ) ;
#endif
  long end = (long) luaL_optnumber(L, 5, -1);
#if VERBOSE
  printf( "\t\t[END position: %ld]\n", end ) ;
#endif
  if (start < 0) start = (long) (nbytes+start+1);
  if (end < 0) end = (long) (nbytes+end+1);
  if (start < 1) start = (long) 1;
  if (end > (long) nbytes) end = (long) nbytes;
  if (start <= end) err = sendraw(&p_tcp->buf, data+start-1, end-start+1, &sent) ;
/*socket_send( &p_tcp->sock, (data + start-1),end-start+1, &sent, &p_tcp->tm ) ;*/
#if VERBOSE
  printf( "\t\t[socket_send returns %d]\n", err ) ;
#endif
    if (err != IO_DONE) {
        lua_pushnil(L);
        lua_pushstring(L, "timeout");
        lua_pushnumber(L, sent+start-1);
      #if VERBOSE
        printf( "\t\t[TIMEOUT sent: %ld]\n", sent+start-1 ) ;
      #endif
    } else {
        lua_pushnumber(L, sent+start-1);
        lua_pushnil(L);
        lua_pushnil(L);
      #if VERBOSE
        printf( "\t\t[DONE sent: %ld]\n", sent+start-1 ) ;
      #endif
    }
  #if VERBOSE
    printf( "\n\t[send() FIM]\n\n" ) ;
  #endif
  return 3 ;
}

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
  t_tcp* p_tcp = (t_tcp*) lua_touserdata( L, 1 ) ;
#if VERBOSE
  printf( "\t\t[P_TCP(%p)]\n", p_tcp ) ;
  printf( "\t\t[Socket ID: %d]\n", p_tcp->sock ) ;
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
  int ret = socket_recv( &p_tcp->sock, (data + dataPosition), nbytes, &got, &p_tcp->tm ) ;
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
      printf( "%c", ptr[ x ] ) ;
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

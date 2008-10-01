/*
** ftc.cpp
*/

#include <ftc.h>

#include <lua.hpp>
extern "C" {
  #include "luasocket.h"
#ifndef WITHOUT_OIL
  #include "oilall.h"
  #include "ftc_core.h"
#else
  #include "ftcwooil_core.h"
#endif
}
#include <string.h>

Lua_State* ftc::LuaVM = 0 ;

void ftc::setEnv()
{
  luaL_openlibs( LuaVM ) ;
  /* Inicializa��o do OiL */
  // preload the LuaSocket library
  luaL_findtable(LuaVM, LUA_GLOBALSINDEX, "package.preload", 1);
  lua_pushcfunction(LuaVM, luaopen_socket_core);
  lua_setfield(LuaVM, -2, "socket.core");
#ifndef WITHOUT_OIL
  // preload all OiL libraries
  luapreload_oilall(LuaVM);
  luaopen_ftc_verbose(LuaVM);
  luaopen_ftc_core(LuaVM);
  luaopen_ftc(LuaVM);
#else
  luaopen_ftc_core(LuaVM);
  luaopen_ftcwooil(LuaVM);
#endif
  lua_pop( LuaVM, 1 ) ;
}

void ftc::setLuaVM( Lua_State* L )
{
  LuaVM = L ;
  setEnv() ;
}

Lua_State* ftc::getLuaVM()
{
  return LuaVM ;
}

ftc::ftc( const char* id, bool writable, unsigned long long size, const char* host, \
                                      unsigned long port, const char* accessKey )
{
#if VERBOSE
  printf( "\n\n[ftc::ftc() COMECO]\n" ) ;
  printf( "\t[Criando instancia de ftc(%p)]\n", this ) ;
#endif
  if ( LuaVM == 0 ) {
    LuaVM = lua_open() ;
  #if VERBOSE
    printf( "\t[lua_State criado...]\n" ) ;
  #endif
    setEnv() ;
  #if VERBOSE
    printf( "\t[Libs de Lua carregadas...]\n" ) ;
  #endif
  #if VERBOSE
    lua_getglobal( LuaVM, "ftc" ) ;
    printf( "\t[Lib ftc(%p) carregada...]\n", \
            lua_topointer( LuaVM, -1 ) ) ;
    lua_pop( LuaVM, 1 ) ;
  #endif
  }
  #if VERBOSE
    printf( "\t[Criando inst�ncia Lua de ftc...]\n" ) ;
  #endif
  lua_getglobal( LuaVM, "ftc" ) ;
  lua_pushstring( LuaVM, id ) ;
  #if VERBOSE
    printf( "\t[par�metro id = %s empilhado]\n", id ) ;
  #endif
  lua_pushboolean( LuaVM, writable ) ;
  #if VERBOSE
    printf( "\t[par�metro writable = %d empilhado]\n", writable ) ;
  #endif
  lua_pushinteger( LuaVM, size ) ;
  #if VERBOSE
    printf( "\t[par�metro size = %Ld empilhado]\n", size ) ;
  #endif
  lua_pushstring( LuaVM, host ) ;
  #if VERBOSE
    printf( "\t[par�metro host = %s empilhado]\n", host ) ;
  #endif
  lua_pushinteger( LuaVM, port ) ;
  #if VERBOSE
    printf( "\t[par�metro port = %d empilhado]\n", (int) port ) ;
  #endif
  lua_pushlstring( LuaVM, accessKey, 16 ) ;
  #if VERBOSE
    printf( "\t[par�metro accessKey = %s empilhado]\n", accessKey ) ;
  #endif
  lua_pcall( LuaVM, 6, 1, 0 ) ;
  #if VERBOSE
    printf( "\t[Inst�ncia Lua de ftc(%p) criada]\n", \
            lua_topointer( LuaVM, -1 ) ) ;
  #endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::ftc() FIM]\n\n" ) ;
#endif
}

ftc::~ftc()
{
#if VERBOSE
  printf( "[Destruindo objeto ftc (%p)...]\n", this ) ;
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  printf( "[Liberando referencia Lua:%p]\n", lua_topointer( LuaVM, -1 ) ) ;
  lua_pop( LuaVM, 1 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_pushnil( LuaVM ) ;
  lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "[Objeto ftc(%p) destruido!]\n\n", this ) ;
#endif
}

void ftc::open( bool readonly )
{
#if VERBOSE
  printf( "[ftc::open() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "open" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushboolean( LuaVM, readonly ) ;
#if VERBOSE
  printf( "\t[par�metro readonly = %d empilhado]\n", readonly ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 4, 3, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 2, 3, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::open() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
    int errorCode = (int) lua_tointeger( LuaVM, -1 ) ;
    lua_pop( LuaVM, 3 ) ;
  #if VERBOSE
    printf( "\t[errorCode = %d]\n", errorCode ) ;
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::open() FIM]\n\n" ) ;
  #endif
    if ( errorCode == 253 ) {
      throw Error::FILE_NOT_FOUND() ;
    } else if ( errorCode == 252 ) {
      throw Error::NO_PERMISSION() ;
    } else {
      throw errmsg ;
    }
  }
  lua_pop( LuaVM, 3 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::open() FIM]\n\n" ) ;
#endif
}

bool ftc::isOpen()
{
#if VERBOSE
  printf( "[ftc::isOpen() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "isOpen" ) ;
  lua_insert( LuaVM, -2 ) ;
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 1, 1, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::isOpen() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -1 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  lua_pop( LuaVM, 1 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::isOpen() FIM]\n\n" ) ;
#endif
  return returnValue ;
}

void ftc::close()
{
#if VERBOSE
  printf( "[ftc::close() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "close" ) ;
  lua_insert( LuaVM, -2 ) ;
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 3, 3, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 1, 3, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::close() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
    int errorCode = (int) lua_tointeger( LuaVM, -1 ) ;
    lua_pop( LuaVM, 3 ) ;
  #if VERBOSE
    printf( "\t[errorCode = %d]\n", errorCode ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::close() FIM]\n\n" ) ;
  #endif
    if ( errorCode == 250 ) {
      throw Error::FILE_NOT_OPENED() ;
    } else {
      throw errmsg ;
    }
  }
  lua_pop( LuaVM, 3 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::close() FIM]\n\n" ) ;
#endif
}

void ftc::truncate( unsigned long long size )
{
#if VERBOSE
  printf( "[ftc::truncate() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "truncate" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushinteger( LuaVM, size ) ;
#if VERBOSE
  printf( "\t[par�metro size = %Ld empilhado]\n", size ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 4, 3, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 2, 3, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::truncate() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
    int errorCode = (int) lua_tointeger( LuaVM, -1 ) ;
    lua_pop( LuaVM, 3 ) ;
  #if VERBOSE
    printf( "\t[errorCode = %d]\n", errorCode ) ;
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::truncate() FIM]\n\n" ) ;
  #endif
    if ( errorCode == 249 ) {
      throw Error::IS_READ_ONLY_FILE() ;
    } else {
      throw errmsg ;
    }
  }
  lua_pop( LuaVM, 3 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::truncate() FIM]\n\n" ) ;
#endif
}

void ftc::setPosition( unsigned long long position )
{
#if VERBOSE
  printf( "[ftc::setPosition() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "setPosition" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushinteger( LuaVM, position ) ;
#if VERBOSE
  printf( "\t[par�metro position = %Ld empilhado]\n", position ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 4, 2, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 2, 2, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::setPosition() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -2 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::setPosition() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    throw errmsg ;
  }
  lua_pop( LuaVM, 2 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::setPosition() FIM]\n\n" ) ;
#endif
}

unsigned long long ftc::getPosition()
{
  unsigned long long position ;
#if VERBOSE
  printf( "[ftc::getPosition() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "getPosition" ) ;
  lua_insert( LuaVM, -2 ) ;
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 3, 2, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 1, 2, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getPosition() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -2 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getPosition() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    throw errmsg ;
  } else {
    position = lua_tointeger( LuaVM, -1 ) ;
  #if VERBOSE
    printf( "\t[position = %Ld empilhado]\n", position ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    return position ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::getPosition() FIM]\n\n" ) ;
#endif
}

unsigned long long ftc::getSize()
{
  unsigned long long size ;
#if VERBOSE
  printf( "[ftc::getSize() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "getSize" ) ;
  lua_insert( LuaVM, -2 ) ;
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 3, 2, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 1, 2, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getSize() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -2 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getSize() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    throw errmsg ;
  } else {
    size = lua_tointeger( LuaVM, -1 ) ;
  #if VERBOSE
    printf( "\t[size = %Ld empilhado]\n", size ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    return size ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::getSize() FIM]\n\n" ) ;
#endif
}

void ftc::read( char* data, size_t nbytes, unsigned long long position )
{
#if VERBOSE
  printf( "[ftc::read() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "read" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushinteger( LuaVM, (int) nbytes ) ;
#if VERBOSE
  printf( "\t[par�metro nbytes = %d empilhado]\n", (int) nbytes ) ;
#endif
  lua_pushinteger( LuaVM, (int) position ) ;
#if VERBOSE
  printf( "\t[par�metro position = %Ld empilhado]\n", position ) ;
#endif
  lua_pushlightuserdata( LuaVM, data ) ;
#if VERBOSE
  printf( "\t[data = %p empilhado]\n", data ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 6, 2, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 4, 2, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::read() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -2 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::read() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    throw errmsg ;
  } else {
  #if VERBOSE
    char* ptr_data = (char*) lua_topointer( LuaVM, -1 ) ;
    printf( "\t[Data buffer recovered: %p]\n", ptr_data ) ;
    printf( "\t[Byte Sequence:" ) ;
  #if VERBOSE2
    int x ;
    for ( x = 0; x < (int) nbytes; x++ ) {
      printf( "%c", ptr_data[ x ] ) ;
    }
  #endif
    printf( "]\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::read() FIM]\n\n" ) ;
#endif
}

void ftc::write( char* data, size_t nbytes, unsigned long long position )
{
#if VERBOSE
  printf( "[ftc::write() COMECO]\n" ) ;
#endif
#ifndef WITHOUT_OIL
  lua_getglobal(LuaVM, "ftc");
  lua_getfield(LuaVM, -1, "invoke" );
  lua_insert( LuaVM, -2 ) ;
#endif
  lua_pushlightuserdata( LuaVM, this ) ;
  lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
#if VERBOSE
  printf( "\t[Objeto C++(%p) Objeto Lua(%p)]\n", this, lua_topointer( LuaVM, -1 ) ) ;
#endif
  lua_getfield( LuaVM, -1, "write" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushinteger( LuaVM, nbytes ) ;
#if VERBOSE
  printf( "\t[par�metro nbytes = %d empilhado]\n", (int) nbytes ) ;
#endif
  lua_pushinteger( LuaVM, position ) ;
#if VERBOSE
  printf( "\t[par�metro position = %Ld empilhado]\n", position ) ;
#endif
  lua_pushlstring( LuaVM, data, nbytes ) ;
#if VERBOSE
  printf( "\t[data = %p empilhado]\n", data ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 6, 2, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 4, 2, 0 ) != 0 ) {
#endif
  #if VERBOSE
    printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::write() FIM]\n\n" ) ;
  #endif
    throw errmsg ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -2 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::write() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    throw errmsg ;
  } else {
  #if VERBOSE
  #endif
    lua_pop( LuaVM, 2 ) ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::write() FIM]\n\n" ) ;
#endif
}


/**
 * ftc.cpp
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

using namespace std;

Lua_State* ftc::LuaVM = 0 ;

void ftc::setEnv()
{
  luaL_openlibs( LuaVM ) ;
  /* Inicialização do OiL */
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

ftc::ftc( const char* id, bool writable, const char* host, \
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
    printf( "\t[Criando instância Lua de ftc...]\n" ) ;
  #endif
  lua_getglobal( LuaVM, "ftc" ) ;
  lua_pushstring( LuaVM, id ) ;
  #if VERBOSE
    printf( "\t[parâmetro id = %s empilhado]\n", id ) ;
  #endif
  lua_pushboolean( LuaVM, writable ) ;
  #if VERBOSE
    printf( "\t[parâmetro writable = %d empilhado]\n", writable ) ;
  #endif
  lua_pushstring( LuaVM, host ) ;
  #if VERBOSE
    printf( "\t[parâmetro host = %s empilhado]\n", host ) ;
  #endif
  lua_pushinteger( LuaVM, port ) ;
  #if VERBOSE
    printf( "\t[parâmetro port = %d empilhado]\n", (int) port ) ;
  #endif
  lua_pushlstring( LuaVM, accessKey, 16 ) ;
  #if VERBOSE
    printf( "\t[parâmetro accessKey = %s empilhado]\n", accessKey ) ;
  #endif
  lua_pcall( LuaVM, 5, 1, 0 ) ;
  #if VERBOSE
    printf( "\t[Instância Lua de ftc(%p) criada]\n", \
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
  printf( "\t[parâmetro readonly = %d empilhado]\n", readonly ) ;
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
    string errmsg ;
    lua_getglobal( LuaVM, "tostring" ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_pcall( LuaVM, 1, 1, 0 ) ;
    errmsg += lua_tostring( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg.c_str() ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::open() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg);
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
    switch(errorCode){
        case FILE_NOT_FOUND:
          throw FileNotFoundException(errmsg);
        case NO_PERMISSION:
          throw NoPermissionException(errmsg);
        case INVALID_KEY:
          throw InvalidKeyException(errmsg);
        default:
          throw FailureException(errmsg);
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
    throw FailureException(errmsg) ;
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
    throw FailureException(errmsg) ;
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
    if(errorCode == FILE_NOT_OPEN ) 
        throw FileNotOpenException(errmsg);
    
    throw FailureException(errmsg);
  }
  lua_pop( LuaVM, 3 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::close() FIM]\n\n" ) ;
#endif
}

void ftc::setSize( unsigned long long size )
{
#if VERBOSE
  printf( "[ftc::setSize() COMECO]\n" ) ;
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
  lua_getfield( LuaVM, -1, "setSize" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushinteger( LuaVM, size ) ;
#if VERBOSE
  printf( "\t[parâmetro size = %lld empilhado]\n", size ) ;
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
    printf( "[ftc::setSize() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg);
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
    printf( "[ftc::setSize() FIM]\n\n" ) ;
  #endif
    switch(errorCode){
        case FILE_NOT_OPEN:
          throw FileNotOpenException(errmsg);
        case NO_PERMISSION:
          throw NoPermissionException(errmsg);
        default:
          throw FailureException(errmsg);
    }
  }
  lua_pop( LuaVM, 3 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::setSize() FIM]\n\n" ) ;
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
  printf( "\t[parâmetro position = %lld empilhado]\n", position ) ;
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
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::setPosition() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg) ;
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
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::setPosition() FIM]\n\n" ) ;
  #endif
    switch(errorCode){
        case FILE_NOT_OPEN:
          throw FileNotOpenException(errmsg);
        case NO_PERMISSION:
          throw NoPermissionException(errmsg);
        default:
          throw FailureException(errmsg);
    }
  }
  lua_pop( LuaVM, 3 ) ;
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
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getPosition() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg) ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getPosition() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
    throw FailureException(errmsg) ;
  } else {
    position = lua_tointeger( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[position = %lld empilhado]\n", position ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
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
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getSize() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg) ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::getSize() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
    throw FailureException(errmsg) ;
  } else {
    size = lua_tointeger( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[size = %lld empilhado]\n", size ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
    return size ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::getSize() FIM]\n\n" ) ;
#endif
}

unsigned long long ftc::getReadBufferSize()
{
  unsigned long long size ;
#if VERBOSE
  printf( "[ftc::getReadBufferSize() COMECO]\n" ) ;
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
  lua_getfield( LuaVM, -1, "getReadBufferSize" ) ;
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
    printf( "[ftc::getReadBufferSize() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg) ;
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
    printf( "[ftc::getReadBufferSize() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    throw FailureException(errmsg) ;
  } else {
    size = lua_tointeger( LuaVM, -1 ) ;
  #if VERBOSE
    printf( "\t[size = %lld empilhado]\n", size ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    return size ;
  }
}

void ftc::setReadBufferSize( unsigned long long size )
{
#if VERBOSE
  printf( "[ftc::setReadBufferSize() COMECO]\n" ) ;
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
  lua_getfield( LuaVM, -1, "setReadBufferSize" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushinteger( LuaVM, size ) ;
#if VERBOSE
  printf( "\t[parâmetro size = %Ld empilhado]\n", size ) ;
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
    printf( "[ftc::setReadBufferSize() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg) ;
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
    printf( "[ftc::setReadBufferSize() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 2 ) ;
    throw FailureException(errmsg) ;
  }
  lua_pop( LuaVM, 2 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::setSize() FIM]\n\n" ) ;
#endif
}

unsigned long long ftc::transferTo( unsigned long long position, unsigned long long nbytes, FILE* fd, char * data  )
{
#if VERBOSE
  printf( "[ftc::transferTo() COMECO]\n" ) ;
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
  lua_getfield( LuaVM, -1, "transferTo" ) ;
  lua_insert( LuaVM, -2 ) ;
  lua_pushinteger( LuaVM, position ) ;
#if VERBOSE
  printf( "\t[parâmetro position = %lld empilhado]\n", position ) ;
#endif
  lua_pushinteger( LuaVM, nbytes ) ;
#if VERBOSE
  printf( "\t[parâmetro nbytes = %lld empilhado]\n", nbytes ) ;
#endif
  lua_pushlightuserdata( LuaVM, (void*)fd ) ;
#if VERBOSE
  printf( "\t[fd = %p empilhado]\n", fd ) ;
#endif
  lua_pushlightuserdata( LuaVM, data ) ;
#if VERBOSE
  printf( "\t[data = %p empilhado]\n", data ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 7, 3, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 5, 3, 0 ) != 0 ) {
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
    throw FailureException(errmsg) ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  unsigned long long readBytes = 0;
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::read() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
    throw FailureException(errmsg) ;
  } else {
    readBytes = lua_tointeger( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[Bytes lidos: %lld]\n" , readBytes ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::read() FIM]\n\n" ) ;
#endif
  return readBytes;
}

unsigned long long ftc::read( char* data, unsigned long long nbytes, unsigned long long position )
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
  lua_pushinteger( LuaVM, nbytes ) ;
#if VERBOSE
  printf( "\t[parâmetro nbytes = %lld empilhado]\n", nbytes ) ;
#endif
  lua_pushinteger( LuaVM, position ) ;
#if VERBOSE
  printf( "\t[parâmetro position = %lld empilhado]\n", position ) ;
#endif
  lua_pushlightuserdata( LuaVM, data ) ;
#if VERBOSE
  printf( "\t[data = %p empilhado]\n", data ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 6, 3, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 4, 3, 0 ) != 0 ) {
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
    throw FailureException(errmsg) ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  unsigned long long readBytes = 0;
  if ( false ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
    lua_pop( LuaVM, 3 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::read() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg) ;
  } else {
    readBytes = lua_tointeger( LuaVM, -1 ) ;
  #if VERBOSE
    printf( "\t[Bytes lidos: %lli]\n" , readBytes ) ;
    char* ptr_data = (char*) lua_topointer( LuaVM, -2 ) ;
    printf( "\t[Data buffer recovered: %p]\n", ptr_data ) ;
  #if VERBOSE2
    printf( "\t[Byte Sequence:" ) ;
    int x ;
    for ( x = 0; x < nbytes; x++ ) {
      printf( "%c", ptr_data[ x ] ) ;
    }
    printf( "]\n" ) ;
  #endif
  #endif
    lua_pop( LuaVM, 3 ) ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::read() FIM]\n\n" ) ;
#endif
  return readBytes;
}

unsigned long long ftc::write( const char* data, unsigned long long nbytes, unsigned long long position )
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
  printf( "\t[parâmetro nbytes = %lldd empilhado]\n", nbytes ) ;
#endif
  lua_pushinteger( LuaVM, position ) ;
#if VERBOSE
  printf( "\t[parâmetro position = %lld empilhado]\n", position ) ;
#endif
  lua_pushlstring( LuaVM, data, nbytes ) ;
#if VERBOSE
  printf( "\t[data = %p empilhado]\n", data ) ;
#endif
#ifndef WITHOUT_OIL
  if ( lua_pcall( LuaVM, 6, 3, 0 ) != 0 ) {
#else
  if ( lua_pcall( LuaVM, 4, 3, 0 ) != 0 ) {
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
    lua_pop( LuaVM, 1) ;
  #if VERBOSE
    printf( "\t[lancando excecao: %s]\n", errmsg ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::write() FIM]\n\n" ) ;
  #endif
    throw FailureException(errmsg) ;
  } /* if */
  bool returnValue = lua_toboolean( LuaVM, -3 ) ;
#if VERBOSE
  printf( "\t[return = %d empilhado]\n", returnValue ) ;
#endif
  unsigned long long readBytes = 0;
  if ( !returnValue ) {
    const char* errmsg = lua_tostring( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[lancando excecao]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[ftc::write() FIM]\n\n" ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
    throw FailureException(errmsg) ;
  } else {
    readBytes = lua_tointeger( LuaVM, -2 ) ;
  #if VERBOSE
    printf( "\t[Bytes lidos: %lld]\n" , readBytes ) ;
  #endif
    lua_pop( LuaVM, 3 ) ;
  }
#if VERBOSE
  printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  printf( "[ftc::write() FIM]\n\n" ) ;
#endif
  return readBytes;
}


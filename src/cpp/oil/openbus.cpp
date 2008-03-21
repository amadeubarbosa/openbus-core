/*
* oil/openbus.cpp
*/

extern "C" {
  #include "openbus/oil/auxiliar.h"
}
#include <openbus/oil/openbus.h>
#include <lua.hpp>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

namespace openbus {

    lua_State* Openbus::LuaVM = 0 ;
    Openbus* Openbus::pInstance = 0 ;

    Lua_State* Openbus::getLuaVM( void )
    {
      return LuaVM ;
    }

    void Openbus::initLuaVM( void )
    {
    #if VERBOSE
      printf( "\t[Carregando bibliotecas de Lua...]\n" ) ;
    #endif
      luaL_openlibs( LuaVM ) ;
    #if VERBOSE
      printf( "\t[Tentando carregar arquivo openbus.lua...]\n" ) ;
    #endif
      lua_pushcfunction( LuaVM, common::ClientInterceptor::sendrequest ) ;
      lua_setglobal( LuaVM, "CPPsendrequest" ) ;
      luaopen_openbus( LuaVM ) ;
      lua_pop( LuaVM, 1 ) ;
    }

    Openbus::Openbus()
    {
    #if VERBOSE
      printf( "\n\n[Openbus::Openbus() COMECO]\n" ) ;
      printf( "\t[Criando instancia de Openbus]\n" ) ;
    #endif
      LuaVM = lua_open() ;
      initLuaVM() ;
    #if VERBOSE
      printf( "[Openbus::Openbus() FIM]\n\n" ) ;
    #endif
    }

    Openbus::~Openbus()
    {
      pInstance = 0 ;
    }

    Openbus* Openbus::getInstance()
    {
      if ( pInstance == 0 )
      {
        new Openbus ;
      }
      return pInstance ;
    }

    void Openbus::setclientinterceptor( common::ClientInterceptor* clientInterceptor )
    {
    #if VERBOSE
      printf( "[Openbus::setclientinterceptor() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Chamando metodo %s( %p )]\n", "oil.setclientinterceptor", clientInterceptor ) ;
    #endif
      lua_getglobal( LuaVM, "oil" ) ;
      lua_getfield( LuaVM, -1, "setclientinterceptor" ) ;
      lua_newtable( LuaVM ) ;
      lua_pushstring( LuaVM, "clientInterceptor" ) ;
      lua_pushlightuserdata( LuaVM, clientInterceptor ) ;
      lua_settable( LuaVM, -3 ) ;
    #if VERBOSE
      printf( "\t[parametro {}.clientInterceptor (pointer) empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, "sendrequest" ) ;
      lua_getglobal( LuaVM, "CPPsendrequest" ) ;
      lua_settable( LuaVM, -3 ) ;
    #if VERBOSE
      printf( "\t[parametro {}.sendrequest (function) empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 1, 0, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
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
        printf( "[Openbus::setclientinterceptor() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
    #if VERBOSE
    /* retira a tabela oil */
      lua_pop( LuaVM, 1 ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[Openbus::setclientinterceptor() FIM]\n\n" ) ;
    #endif
    }

    services::IAccessControlService* Openbus::getACS( String reference, String interface )
    {
      return new services::IAccessControlService( reference, interface ) ;
    }

}

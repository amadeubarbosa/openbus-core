/*
* oil/common/ClientInterceptor.cpp
*/

#include <openbus/oil/common/ClientInterceptor.h>
#include <lua.hpp>

namespace openbus {
  namespace common {
      int ClientInterceptor::sendrequest( lua_State* L )
      {
      #if VERBOSE2
        printf( "\n\n\t[Lua chamando ClientInterceptor::sendrequest() COMECO]\n" ) ;
      #endif
        lua_getfield( L, 1, "clientInterceptor" ) ;
        common::ClientInterceptor* clientInterceptor = (common::ClientInterceptor*) lua_topointer( L, -1 ) ;
        services::Credential* credential = clientInterceptor->credentialManager->getValue() ;
        lua_pop( L, 1 ) ;
      #if VERBOSE2
        printf( "\t\t[POP ponteiro para ClientInterceptor]\n" ) ;
      #endif
        lua_pushlightuserdata( L, clientInterceptor ) ;
        lua_insert( L, -2 ) ;
        lua_settable(L, LUA_REGISTRYINDEX ) ;
        if ( ! clientInterceptor->credentialManager->hasValue() ) {
          return 0 ;
        }
        lua_getglobal( Openbus::LuaVM, "sendrequest" ) ;
      /* Credential */
        lua_newtable( Openbus::LuaVM ) ;
        lua_pushstring( Openbus::LuaVM, "identifier" ) ;
        lua_pushstring( Openbus::LuaVM, credential->identifier ) ;
        lua_settable( Openbus::LuaVM, -3 ) ;
        lua_pushstring( Openbus::LuaVM, "entityName" ) ;
        lua_pushstring( Openbus::LuaVM, credential->entityName ) ;
        lua_settable( Openbus::LuaVM, -3 ) ;
      /* CredentialType */
        lua_pushstring( Openbus::LuaVM, clientInterceptor->credentialType ) ;
      /* ContextID */
        lua_pushnumber( Openbus::LuaVM, clientInterceptor->contextID ) ;
      /* Request */
        lua_pushlightuserdata( Openbus::LuaVM, clientInterceptor ) ;
        lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      #if VERBOSE2
        printf( "\t\t[Chamando em Lua sendrequest( credential, credentialType, contextID, request)]\n" ) ;
      #endif
        lua_pcall( Openbus::LuaVM, 4, 0, 0 ) ;
      #if VERBOSE2
        printf( "\t[Lua chamando ClientInterceptor::sendrequest FIM]\n\n\n" ) ;
      #endif
        return 0 ;
      }

      ClientInterceptor::ClientInterceptor ( String configPATH, CredentialManager* pcredentialManager )
      {
      #if VERBOSE
        printf( "\n\n[ClientInterceptor::ClientInterceptor() COMECO]\n" ) ;
        printf( "\t[Criando instancia de ClientInterceptor]\n" ) ;
      #endif
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Carregando arquivo de cofiguracao: %s]\n" , configPATH ) ;
      #endif
        if ( luaL_dofile( Openbus::LuaVM, configPATH ) != 0 ) {
          const char * returnValue ;
          lua_getglobal( Openbus::LuaVM, "tostring" ) ;
          lua_insert( Openbus::LuaVM, -2 ) ;
          lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
          returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
          lua_pop( Openbus::LuaVM, 1 ) ;
          throw returnValue ;
        } /*if */
        if ( ! lua_istable( Openbus::LuaVM, -1 ) ) {
          throw "ClientInterceptor: Lua table expected" ;
        } /*if */
        lua_getfield( Openbus::LuaVM, -1, "contextID" ) ;
        contextID = (Long) lua_tonumber( Openbus::LuaVM, -1 ) ;
      #if VERBOSE
        printf( "\t[contextID=%d]\n" , (int) contextID ) ;
      #endif
        lua_pop( Openbus::LuaVM, 1 ) ;
        lua_getfield( Openbus::LuaVM, -1, "credential_type" ) ;
        credentialType = lua_tostring( Openbus::LuaVM, -1 ) ;
        credentialManager = pcredentialManager ;
      #if VERBOSE
        printf( "\t[credentialType=%s]\n" ,  credentialType ) ;
        printf( "\t[credentialManager=%p]\n" ,  credentialManager ) ;
      #endif
        lua_pop( Openbus::LuaVM, 2 ) ;
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[ClientInterceptor::ClientInterceptor() FIM]\n\n" ) ;
      #endif
      }

      ClientInterceptor::~ClientInterceptor () {}
  }
}

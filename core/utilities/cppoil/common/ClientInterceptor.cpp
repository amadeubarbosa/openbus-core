/*
** common/ClientInterceptor.cpp
*/

#include "ClientInterceptor.h"
#include <lua.hpp>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 1024

namespace openbus {
  namespace common {

    Lua_State* ClientInterceptor::LuaVM = 0;

    int ClientInterceptor::sendrequest(lua_State* L) {
    #if VERBOSE2
      printf("\n\n\t[Lua chamando ClientInterceptor::sendrequest() COMECO]\n");
    #endif
      lua_getfield(L, 1, "clientInterceptor");
      common::ClientInterceptor* clientInterceptor = (common::ClientInterceptor*) lua_topointer(L, -1);
      services::Credential* credential = clientInterceptor->credentialManager->getValue();
      lua_pop(L, 1);
    #if VERBOSE2
      printf("\t\t[POP ponteiro para ClientInterceptor]\n");
    #endif
      lua_pushlightuserdata(L, clientInterceptor);
      lua_insert(L, -2);
      lua_settable(L, LUA_REGISTRYINDEX);
      if (!clientInterceptor->credentialManager->hasValue()) {
        return 0 ;
      }
      lua_getglobal(LuaVM, "sendrequest");
    /* Credential */
      lua_newtable(LuaVM);
      lua_pushstring(LuaVM, "identifier");
      lua_pushstring(LuaVM, credential->identifier);
      lua_settable(LuaVM, -3);
      lua_pushstring(LuaVM, "owner");
      lua_pushstring(LuaVM, credential->owner);
      lua_settable(LuaVM, -3);
      lua_pushstring(LuaVM, "delegate");
      lua_pushstring(LuaVM, credential->delegate);
      lua_settable(LuaVM, -3);
    /* CredentialType */
      lua_pushstring(LuaVM, clientInterceptor->credentialType);
    /* ContextID */
      lua_pushnumber(LuaVM, clientInterceptor->contextID);
    /* Request */
      lua_pushlightuserdata(LuaVM, clientInterceptor);
      lua_gettable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE2
      printf("\t\t[Chamando em Lua sendrequest( credential, credentialType, contextID, request)]\n");
    #endif
      lua_pcall(LuaVM, 4, 0, 0);
    #if VERBOSE2
      printf("\t[Lua chamando ClientInterceptor::sendrequest FIM]\n\n\n");
    #endif
      return 0;
    }

    ClientInterceptor::ClientInterceptor(CredentialManager* pcredentialManager) {
    #if VERBOSE
      printf("\n\n[ClientInterceptor::ClientInterceptor() COMECO]\n");
      printf("\t[Criando instancia de ClientInterceptor]\n");
    #endif
      openbus = Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
      const char* OPENBUS_HOME = getenv("OPENBUS_HOME");
      char* configPath = new char[BUFFER_SIZE];
      strcpy(configPath, OPENBUS_HOME);
      strcat(configPath, "/core/conf/advanced/InterceptorsConfiguration.lua");
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando arquivo de cofiguracao: %s]\n" , configPath);
    #endif
      if (luaL_dofile(LuaVM, configPath) != 0) {
        const char * returnValue;
        lua_getglobal(LuaVM, "tostring");
        lua_insert(LuaVM, -2);
        lua_pcall(LuaVM, 1, 1, 0);
        returnValue = lua_tostring(LuaVM, -1);
        lua_pop(LuaVM, 1);
        throw returnValue;
      } /*if */
      if (!lua_istable(LuaVM, -1)) {
        throw "ClientInterceptor: Lua table expected" ;
      } /*if */
      lua_getfield(LuaVM, -1, "contextID");
      contextID = (Long) lua_tonumber(LuaVM, -1);
    #if VERBOSE
      printf("\t[contextID=%d]\n" , (int) contextID);
    #endif
      lua_pop(LuaVM, 1);
      lua_getfield(LuaVM, -1, "credential_type");
      credentialType = lua_tostring(LuaVM, -1);
      credentialManager = pcredentialManager;
    #if VERBOSE
      printf("\t[credentialType=%s]\n", credentialType);
      printf("\t[credentialManager=%p]\n", credentialManager);
    #endif
      lua_pop(LuaVM, 2);
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
      printf("[ClientInterceptor::ClientInterceptor() FIM]\n\n");
    #endif
    }

    ClientInterceptor::~ClientInterceptor () {}
  }
}

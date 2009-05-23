/*
** common/ServerInterceptor.cpp
*/

#include "ServerInterceptor.h"
#include <lua.hpp>
#include <stdlib.h>
#include <string.h>
#include <iostream>

#define BUFFER_SIZE 1024

using namespace std;

namespace openbus {
  namespace common {

    Lua_State* ServerInterceptor::LuaVM = 0;

    ServerInterceptor::ServerInterceptor() {
    #if VERBOSE
      printf("\n\n[ServerInterceptor::ServerInterceptor() COMECO]\n");
      printf("\t[Criando instancia de ServerInterceptor]\n");
    #endif
      openbus = Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
      lua_newtable(LuaVM);
      lua_pushlightuserdata(LuaVM, this);
      lua_insert(LuaVM, -2);
      lua_settable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
      printf("[ServerInterceptor::ServerInterceptor() FIM]\n\n");
    #endif
    }

    ServerInterceptor::~ServerInterceptor() {
      /* empty */
    }

    services::Credential* ServerInterceptor::getCredential() {
      services::Credential* returnValue;
    #if VERBOSE
      cout << endl << endl << "[ServerInterceptor::getCredential() COMECO]" << endl;
    #endif
      returnValue = new services::Credential;
      lua_getglobal(LuaVM, "getCredential");
      if (lua_pcall(LuaVM, 0, 1, 0) != 0) {
      #if VERBOSE
        printf("\t[ERRO ao realizar pcall do metodo]\n") ;
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM)) ;
        printf("\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename(LuaVM, lua_type(LuaVM, -1))) ;
      #endif
        const char * errmsg ;
        lua_getglobal(LuaVM, "tostring") ;
        lua_insert(LuaVM, -2) ;
        lua_pcall(LuaVM, 1, 1, 0) ;
        errmsg = lua_tostring(LuaVM, -1) ;
        lua_pop(LuaVM, 1) ;
      #if VERBOSE
        printf("\t[lancando excecao: %s]\n", errmsg) ;
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM)) ;
        printf("[ServerInterceptor::getCredential() FIM]\n\n") ;
      #endif
        throw errmsg ;
      }
      lua_getfield(LuaVM, -1, "identifier");
      const char* identifier = lua_tostring(LuaVM, -1);
      returnValue->identifier = identifier;
      lua_pop(LuaVM, 1);
      lua_getfield(LuaVM, -1, "owner");
      const char* owner = lua_tostring(LuaVM, -1);
      returnValue->owner = owner;
      lua_pop(LuaVM, 1);
      lua_getfield(LuaVM, -1, "delegate");
      const char* delegate = lua_tostring(LuaVM, -1);
      returnValue->delegate = delegate;
      lua_pop(LuaVM, 1);
    #if VERBOSE
      cout << endl << endl << "[ServerInterceptor::getCredential() FIM]" << endl;
    #endif
      return returnValue;
    }
  }
}

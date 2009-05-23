/*
** helloStub.cpp
*/

#include <lua.hpp>
#include <openbus.h>
#include "helloStub.h"

static lua_State* LuaVM = 0;

IHello::IHello() {
  if (!LuaVM) {
    openbus::Openbus* openbus = openbus::Openbus::getInstance();
    LuaVM = openbus->getLuaVM();
  }
#if VERBOSE
  printf("[IHello::IHello () COMECO]\n");
  printf("\t[This: %p]\n", this);
#endif

#if VERBOSE
  printf("[IHello::IHello() FIM]\n\n");
#endif
}

IHello::~IHello() {
  /* empty */
}

void IHello::sayHello() {
#if VERBOSE
  printf("[(%p)IHello::sayHello() COMECO]\n", this);
  printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
#endif
  lua_getglobal(LuaVM, "invoke");
  lua_pushlightuserdata(LuaVM, this);
  lua_gettable(LuaVM, LUA_REGISTRYINDEX);
#if VERBOSE
  printf("\t[IFile Lua:%p C++:%p]\n", \
    lua_topointer(LuaVM, -1), this);
  printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
#endif
  lua_getfield(LuaVM, -1, "sayHello");
#if VERBOSE
  printf("\t[metodo getName empilhado]\n");
  printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  printf("\t[Tipo do elemento do TOPO: %s]\n" , \
      lua_typename(LuaVM, lua_type(LuaVM, -1)));
#endif
  lua_insert(LuaVM, -2);
  if (lua_pcall(LuaVM, 2, 0, 0) != 0) {
  #if VERBOSE
    printf("\t[ERRO ao realizar pcall do metodo]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    const char * returnValue;
    lua_getglobal(LuaVM, "tostring");
    lua_insert(LuaVM, -2);
    lua_pcall(LuaVM, 1, 1, 0);
    returnValue = lua_tostring(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[lancando excecao %s]\n", returnValue);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IHello::sayHello() FIM]\n\n");
  #endif
    throw returnValue;
  } /* if */
#if VERBOSE
  printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  printf("[IHello::sayHello() FIM]\n\n");
#endif
}

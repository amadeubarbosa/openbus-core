/*
** openbus.cpp
*/

#include <lua.hpp>
extern "C" {
  #include "auxiliar.h"
  #include <oilall.h>
  #include <scsall.h>
  #include "luasocket.h"
}
#include "openbus.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sstream>

using namespace std;

namespace openbus {

  lua_State* Openbus::LuaVM = 0;
  Openbus* Openbus::instance = 0;
  common::CredentialManager* Openbus::credentialManager = 0;
  common::ClientInterceptor* Openbus::clientInterceptor = 0;

  Lua_State* Openbus::getLuaVM(void) {
    return LuaVM;
  }

  void Openbus::initLuaVM(void) {
  #if VERBOSE
    printf("\t[Carregando bibliotecas de Lua...]\n");
  #endif
    luaL_openlibs(LuaVM);
    luaL_findtable(LuaVM, LUA_GLOBALSINDEX, "package.preload", 1);
    lua_pushcfunction(LuaVM, luaopen_socket_core);
    lua_setfield(LuaVM, -2, "socket.core");
    luapreload_oilall(LuaVM);
    luapreload_scsall(LuaVM);
    scs::core::IComponent::setLuaVM(LuaVM);
  #if VERBOSE
    printf("\t[Tentando carregar arquivo openbus.lua...]\n");
  #endif
    luaopen_openbus(LuaVM);
    lua_pop(LuaVM, 1);
  }

  Openbus::Openbus() {
  #if VERBOSE
    printf("\n\n[Openbus::Openbus() COMECO]\n");
    printf("\t[Criando instancia de Openbus]\n");
  #endif
    LuaVM = lua_open();
    initLuaVM();
  #if VERBOSE
    printf("[Openbus::Openbus() FIM]\n\n");
  #endif
  }

  Openbus::~Openbus() {
    instance = 0;
    delete clientInterceptor;
    delete credentialManager;
  }

  Openbus* Openbus::getInstance() {
    if (instance == 0) {
      instance = new Openbus;
      credentialManager = new common::CredentialManager();
      clientInterceptor = new common::ClientInterceptor(credentialManager);
      instance->setClientInterceptor(clientInterceptor);
    }
    return instance;
  }

  void Openbus::setClientInterceptor(common::ClientInterceptor* clientInterceptor) {
  #if VERBOSE
    printf("[Openbus::setClientInterceptor() COMECO]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Chamando metodo %s( %p )]\n", "oil.setClientInterceptor", clientInterceptor);
  #endif
    lua_getglobal(LuaVM, "orb");
    lua_getfield(LuaVM, -1, "setclientinterceptor");
    lua_getglobal(LuaVM, "orb");
    lua_newtable(LuaVM);
    lua_pushstring(LuaVM, "clientInterceptor");
    lua_pushlightuserdata(LuaVM, clientInterceptor);
    lua_settable(LuaVM, -3);
  #if VERBOSE
    printf("\t[parametro {}.clientInterceptor (pointer) empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_pushstring(LuaVM, "sendrequest");
    lua_pushcfunction(LuaVM, common::ClientInterceptor::sendrequest);
    lua_settable(LuaVM, -3);
  #if VERBOSE
    printf("\t[parametro {}.sendrequest (function) empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    if (lua_pcall(LuaVM, 2, 0, 0) != 0) {
    #if VERBOSE
      printf("\t[ERRO ao realizar pcall do metodo]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Tipo do elemento do TOPO: %s]\n" , lua_typename(LuaVM, lua_type(LuaVM, -1)));
    #endif
      const char * errmsg ;
      lua_getglobal(LuaVM, "tostring");
      lua_insert(LuaVM, -2);
      lua_pcall(LuaVM, 1, 1, 0);
      errmsg = lua_tostring(LuaVM, -1);
      lua_pop(LuaVM, 1);
    #if VERBOSE
      printf("\t[lancando excecao]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[Openbus::setClientInterceptor() FIM]\n\n");
    #endif
      throw errmsg;
    } /* if */
    lua_pop(LuaVM, 1);
  #if VERBOSE
  /* retira a tabela oil */
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[Openbus::setClientInterceptor() FIM]\n\n");
  #endif
  }

  services::IAccessControlService* Openbus::getACS(String host, unsigned short port) {
    stringstream corbaloc;
    corbaloc << "corbaloc::" << host << ":" << port << "/ACS";
    return new services::IAccessControlService(corbaloc.str().c_str(), "IDL:openbusidl/acs/IAccessControlService:1.0");
  }

  services::IAccessControlService* Openbus::connect(String host, unsigned short port, String user, String password, \
        services::Credential* aCredential, services::Lease* aLease) {
    services::IAccessControlService* acs = getACS(host, port);
    if (!acs->loginByPassword(user, password, aCredential, aLease)) {
      return 0;
    } else {
      credentialManager->setValue(aCredential);
      return acs;
    }
  }

}

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
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <sstream>

using namespace std;

namespace openbus {

  lua_State* Openbus::LuaVM = 0;
  Openbus* Openbus::instance = 0;
  common::CredentialManager* Openbus::credentialManager = 0;
  common::ClientInterceptor* Openbus::clientInterceptor = 0;
  common::ServerInterceptor* Openbus::serverInterceptor = 0;

  Lua_State* Openbus::getLuaVM(void) {
    return LuaVM;
  }

  common::ServerInterceptor* Openbus::getServerInterceptor() {
    return serverInterceptor;
  }

  void Openbus::initLuaVM(void) {
  #if VERBOSE
    cout << "\t[Carregando bibliotecas Lua.]" << endl;
  #endif
    luaL_openlibs(LuaVM);
    luaL_findtable(LuaVM, LUA_GLOBALSINDEX, "package.preload", 1);
    lua_pushcfunction(LuaVM, luaopen_socket_core);
    lua_setfield(LuaVM, -2, "socket.core");
    luapreload_oilall(LuaVM);
    luapreload_scsall(LuaVM);
    scs::core::IComponent::setLuaVM(LuaVM);
  #if VERBOSE
    cout << "\t[Tentando carregar arquivo openbus.lua...]" << endl;
  #endif
    luaopen_openbus(LuaVM);
    lua_pop(LuaVM, 1);
  }

  Openbus::Openbus() {
  #if VERBOSE
    cout << endl << endl << "[Openbus::Openbus() COMECO]" << endl;
    cout << "\t[Criando instancia de Openbus]" << endl;
  #endif
    LuaVM = lua_open();
    initLuaVM();
  #if VERBOSE
    cout << "[Openbus::Openbus() FIM]" << endl;
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

  void Openbus::run() {
  #if VERBOSE
    cout << "[Openbus::run()]" << endl;
  #endif
    lua_getglobal(LuaVM, "run");
    if (lua_pcall(LuaVM, 0, 0, 0) != 0) {
    #if VERBOSE
      cout << "\t[ERRO ao realizar pcall do metodo]" << endl;
      cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << endl;
      cout << "\t[Tipo do elemento do TOPO: " << lua_typename(LuaVM, lua_type(LuaVM, -1)) << "]" << endl;
    #endif
      const char * errmsg ;
      lua_getglobal(LuaVM, "tostring");
      lua_insert(LuaVM, -2);
      lua_pcall(LuaVM, 1, 1, 0);
      errmsg = lua_tostring(LuaVM, -1);
      lua_pop(LuaVM, 1);
    #if VERBOSE
      cout << "\t[lancando excecao: " << errmsg << "]" << endl;
      cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
      cout << "[Openbus::run() FIM]" << endl << endl;
    #endif
      throw errmsg;
    }
  }

  void Openbus::setClientInterceptor(common::ClientInterceptor* clientInterceptor) {
  #if VERBOSE
    cout << "[Openbus::setClientInterceptor() COMECO]" << endl;
    cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
    cout << "\t[Chamando metodo orb:setClientInterceptor(" << clientInterceptor << ")]" << endl;
  #endif
    lua_getglobal(LuaVM, "orb");
    lua_getfield(LuaVM, -1, "setclientinterceptor");
    lua_getglobal(LuaVM, "orb");
    lua_newtable(LuaVM);
    lua_pushstring(LuaVM, "clientInterceptor");
    lua_pushlightuserdata(LuaVM, clientInterceptor);
    lua_settable(LuaVM, -3);
  #if VERBOSE
    cout << "\t[parametro {}.clientInterceptor (pointer) empilhado]" << endl;
    cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
  #endif
    lua_pushstring(LuaVM, "sendrequest");
    lua_pushcfunction(LuaVM, common::ClientInterceptor::sendrequest);
    lua_settable(LuaVM, -3);
  #if VERBOSE
    cout << "\t[parametro {}.sendrequest (function) empilhado]" << endl;
    cout << "\t[Tamanho da pilha de Lua: " <<  lua_gettop(LuaVM) << "]" << endl;
  #endif
    if (lua_pcall(LuaVM, 2, 0, 0) != 0) {
    #if VERBOSE
      cout << "\t[ERRO ao realizar pcall do metodo]" << endl;
      cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << endl;
      cout << "\t[Tipo do elemento do TOPO: " << lua_typename(LuaVM, lua_type(LuaVM, -1)) << "]" << endl;
    #endif
      const char * errmsg ;
      lua_getglobal(LuaVM, "tostring");
      lua_insert(LuaVM, -2);
      lua_pcall(LuaVM, 1, 1, 0);
      errmsg = lua_tostring(LuaVM, -1);
      lua_pop(LuaVM, 1);
    #if VERBOSE
      cout << "\t[lancando excecao]" << endl;
      cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
      cout << "[Openbus::setClientInterceptor() FIM]" << endl << endl;
    #endif
      throw errmsg;
    } /* if */
    lua_pop(LuaVM, 1);
  #if VERBOSE
    cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
    cout << "[Openbus::setClientInterceptor() FIM]" << endl << endl;
  #endif
  }

  void Openbus::setServerInterceptor(common::ServerInterceptor* serverInterceptor) {
  #if VERBOSE
    cout << "[Openbus::setServerInterceptor() COMECO]" << endl;
    cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
    cout << "\t[Chamando metodo orb:setServerInterceptor(" << serverInterceptor << ")]" << endl;
  #endif
    lua_getglobal(LuaVM, "orb");
    lua_getfield(LuaVM, -1, "setserverinterceptor");
    lua_getglobal(LuaVM, "orb");
    lua_newtable(LuaVM);
    lua_pushstring(LuaVM, "serverInterceptor");
    lua_pushlightuserdata(LuaVM, serverInterceptor);
    lua_settable(LuaVM, -3);
  #if VERBOSE
    cout << "\t[parametro {}.clientInterceptor (pointer) empilhado]" << endl;
    cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
  #endif
    lua_pushstring(LuaVM, "receiverequest");
    lua_getglobal(LuaVM, "receiverequest");
    lua_settable(LuaVM, -3);
  #if VERBOSE
    cout << "\t[parametro {}.receiverequest (function) empilhado]" << endl;
    cout << "\t[Tamanho da pilha de Lua: " <<  lua_gettop(LuaVM) << "]" << endl;
  #endif
    if (lua_pcall(LuaVM, 2, 0, 0) != 0) {
    #if VERBOSE
      cout << "\t[ERRO ao realizar pcall do metodo]" << endl;
      cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << endl;
      cout << "\t[Tipo do elemento do TOPO: " << lua_typename(LuaVM, lua_type(LuaVM, -1)) << "]" << endl;
    #endif
      const char * errmsg ;
      lua_getglobal(LuaVM, "tostring");
      lua_insert(LuaVM, -2);
      lua_pcall(LuaVM, 1, 1, 0);
      errmsg = lua_tostring(LuaVM, -1);
      lua_pop(LuaVM, 1);
    #if VERBOSE
      cout << "\t[lancando excecao]" << endl;
      cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
      cout << "[Openbus::setServerInterceptor() FIM]" << endl << endl;
    #endif
      throw errmsg;
    } /* if */
    lua_pop(LuaVM, 1);
  #if VERBOSE
    cout << "\t[Tamanho da pilha de Lua: " << lua_gettop(LuaVM) << "]" << endl;
    cout << "[Openbus::setServerInterceptor() FIM]" << endl << endl;
  #endif
  }

  common::CredentialManager* Openbus::getCredentialManager() {
    return credentialManager;
  }

  services::IAccessControlService* Openbus::getACS(String host, unsigned short port) {
    stringstream corbaloc;
    corbaloc << "corbaloc::" << host << ":" << port << "/ACS";
    return new services::IAccessControlService(corbaloc.str().c_str(), "IDL:openbusidl/acs/IAccessControlService:1.0");
  }

  services::IAccessControlService* Openbus::connect(String host, unsigned short port, String user, String password, \
        services::Credential* aCredential, services::Lease* aLease) {
    try {
      services::IAccessControlService* acs = getACS(host, port);
      serverInterceptor = new common::ServerInterceptor();
      this->setServerInterceptor(serverInterceptor);
      if (!acs->loginByPassword(user, password, aCredential, aLease)) {
        throw "Par usuario/senha nao validado.";
      } else {
        credentialManager->setValue(aCredential);
        return acs;
      }
    } catch (const char* errmsg) {
      throw errmsg;
    }
  }

}

/*
** FaultToleranceManager.cpp
*/

#include "FaultToleranceManager.h"
#include "openbus.h"

#include <lua.hpp>

namespace openbus {
  FaultToleranceManager* FaultToleranceManager::faultToleranceManager = 0;

  FaultToleranceManager::FaultToleranceManager() {
    Openbus::logger->log(INFO, 
      "FaultToleranceManager::FaultToleranceManager() BEGIN");
    Openbus::logger->indent();
    Openbus::logger->dedent(INFO,
      "FaultToleranceManager::FaultToleranceManager() END");
  }

  FaultToleranceManager::~FaultToleranceManager() {
  }

  void FaultToleranceManager::loadConfig(char* filename) {
    Openbus::logger->log(INFO, 
      "FaultToleranceManager::loadConfig() BEGIN");
    Openbus::logger->indent();
    if (luaL_loadfile(Openbus::luaState, filename)) {
      const char* errmsg = lua_tostring(Openbus::luaState, -1);
      lua_pop(Openbus::luaState, 1);
      Openbus::logger->log(ERROR, errmsg);
    } else {
      if (lua_pcall(Openbus::luaState, 0, 0, 0)) {
        const char* errmsg = lua_tostring(Openbus::luaState, -1);
        lua_pop(Openbus::luaState, 1);
        Openbus::logger->log(ERROR, errmsg);
      } else {
        Openbus::logger->log(INFO, 
          "Arquivo de configuracao carregado com sucesso.");
        lua_getglobal(Openbus::luaState, "ACSHosts");
        if (lua_istable(Openbus::luaState, -1)) {
          size_t numACSHosts = lua_objlen(Openbus::luaState, -1);
          stringstream out;
          out << "Numero de replicas: " << numACSHosts;
          Openbus::logger->log(INFO, out.str());
          lua_pushnil(Openbus::luaState);
          while (lua_next(Openbus::luaState, -2)) {
            stringstream out;
            size_t strLen;
            char* name;
            unsigned short port;
            Host* host;
            out << "Replica[" << lua_tonumber(Openbus::luaState, -2) << "]: ";
          /* Obtenho a maquina. */
            lua_pushnumber(Openbus::luaState, 1);
            lua_gettable(Openbus::luaState, -2);
            strLen = lua_objlen(Openbus::luaState, -1); 
            const char* luaString = 
              lua_tolstring(Openbus::luaState, -1, &strLen);
            name = new char[strLen + 1];
            memcpy(name, luaString , strLen);
            name[strLen] = '\0';
            out << name;
            lua_pop(Openbus::luaState, 1);
          /* Obtenho a porta. */
            lua_pushnumber(Openbus::luaState, 2);
            lua_gettable(Openbus::luaState, -2);
            port = (unsigned short) lua_tointeger(Openbus::luaState, -1);
            out << "::" << port;
            lua_pop(Openbus::luaState, 1);
            Openbus::logger->log(INFO, out.str());
          /* Armazenando par maquina/porta na lista de replicas.*/
            host = new Host;
            host->name = name;
            host->port = port;
            acsHosts.push_back(host);
          /* Removo a tabela que discrima a maquina e a porta. */
            lua_pop(Openbus::luaState, 1);
          }
          itACSHosts = acsHosts.begin();
        } else {
          Openbus::logger->log(ERROR, "Ausência da tabela ACSHosts.");
        }    
      }
    }
    Openbus::logger->dedent(INFO, 
      "FaultToleranceManager::loadConfig() END");
  }

  FaultToleranceManager* FaultToleranceManager::getInstance() {
    if (!faultToleranceManager) {
      faultToleranceManager = new FaultToleranceManager();
    }
    return faultToleranceManager;
  }

  void FaultToleranceManager::setACSHostInUse(Host* host) {
    acsHostInUse = host;
  }

  Host* FaultToleranceManager::updateACSHostInUse() {
    Openbus::logger->log(INFO, 
      "FaultToleranceManager::updateACSHostInUse() BEGIN");
    Openbus::logger->indent();
    stringstream out;
    out << "Replica ACS em uso: [" << acsHostInUse->name << "::" << 
      acsHostInUse->port << "]";
    Openbus::logger->log(INFO, out.str());
    out.str(" ");
    itACSHosts++;
    if (itACSHosts == acsHosts.end()) {
      itACSHosts = acsHosts.begin();
    }
    acsHostInUse->name = (*itACSHosts)->name; 
    acsHostInUse->port = (*itACSHosts)->port; 
    out << "Nova replica ACS: [" << acsHostInUse->name  << "::" << 
       acsHostInUse->port << "]";
    Openbus::logger->log(INFO, out.str());
    Openbus::logger->dedent(INFO, 
      "FaultToleranceManager::updateACSHostInUse() END");
    return acsHostInUse;
  }
}

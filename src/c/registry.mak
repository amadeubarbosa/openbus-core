PROJNAME = OpenBUS
APPNAME = registry_service

DEFINES += REGISTRY_SERVICE
SERVICES_DIR=${OPENBUS_HOME}/src/lua/openbus/services
REGISTRY_SERVICE_DIR=${SERVICES_DIR}/registry
LUA_FILE = ${REGISTRY_SERVICE_DIR}/RegistryServer.lua

include ${OPENBUS_HOME}/src/c/lualoader.conf

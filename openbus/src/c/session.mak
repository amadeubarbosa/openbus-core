PROJNAME = OpenBUS
APPNAME = session_service

DEFINES += SESSION_SERVICE
SERVICES_DIR=${OPENBUS_HOME}/src/lua/openbus/services
SESSION_SERVICE_DIR=${SERVICES_DIR}/session
LUA_FILE = ${SESSION_SERVICE_DIR}/SessionServer.lua

include ${OPENBUS_HOME}/src/c/lualoader.conf

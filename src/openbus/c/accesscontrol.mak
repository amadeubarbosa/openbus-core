PROJNAME = OpenBUS
APPNAME = accesscontrol_service

DEFINES += ACCESS_CONTROL_SERVICE
SERVICES_DIR=${OPENBUS_HOME}/src/openbus/lua/openbus/services
ACCESS_CONTROL_SERVICE_DIR=${SERVICES_DIR}/accesscontrol
LUA_FILE = ${ACCESS_CONTROL_SERVICE_DIR}/AccessControlServer.lua

include ${OPENBUS_HOME}/src/openbus/c/lualoader.conf

SLIB += ${OPENBUSLIB}/liblualdap.a

LIBS += ldap

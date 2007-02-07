set LATT_HOME=${LUA_HOME}/share/lua/5.1/latt
set OPENBUS_HOME=../../install

setenv CORBA_IDL_DIR ${OPENBUS_HOME}/corba_idl
setenv CONF_DIR ${OPENBUS_HOME}/conf

set CORE_DIR=${OPENBUS_HOME}/core

set COMPONENTS_DIR=${OPENBUS_HOME}/components
set REGISTRY_SERVICE_DIR=${COMPONENTS_DIR}/registry_service
set ACCESS_CONTROL_SERVICE_DIR=${COMPONENTS_DIR}/access_control_service
set SESSION_SERVICE_DIR=${COMPONENTS_DIR}/session_service

setenv LUA_PATH "${CORE_DIR}/?.lua;${LUA_PATH}"

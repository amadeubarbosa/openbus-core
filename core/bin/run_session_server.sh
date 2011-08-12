#!/bin/ksh

if [ -z "${OPENBUS_HOME}" ] ; then
  echo "[ERRO] Variável de ambiente OPENBUS_HOME não definida"
  exit 1
fi

exec ${OPENBUS_HOME}/bin/servicelauncher ${OPENBUS_HOME}/src/lua/openbus/core/services/session/SessionServer.lua

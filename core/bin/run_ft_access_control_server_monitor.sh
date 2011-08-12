#!/bin/ksh

if [ -z "${OPENBUS_HOME}" ] ; then
  echo "[ERRO] Variável de ambiente OPENBUS_HOME não definida"
  exit 1
fi

${OPENBUS_HOME}/bin/servicelauncher ${OPENBUS_HOME}/src/lua/openbus/core/services/accesscontrol/FTAccessControlServerMonitor.lua "$@"

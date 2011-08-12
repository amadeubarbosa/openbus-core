#!/bin/ksh

if [ -z "${OPENBUS_HOME}" ] ; then
  echo "[ERRO] Vari�vel de ambiente OPENBUS_HOME n�o definida"
  exit 1
fi

${OPENBUS_HOME}/bin/servicelauncher ${OPENBUS_HOME}/src/lua/openbus/core/services/accesscontrol/FTAccessControlServerMonitor.lua "$@"

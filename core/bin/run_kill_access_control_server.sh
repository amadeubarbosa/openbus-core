#!/bin/ksh

if [ -z "${OPENBUS_HOME}" ] ; then
  echo "[ERRO] Vari�vel de ambiente OPENBUS_HOME n�o definida"
  exit 1
fi

${OPENBUS_HOME}/core/bin/servicelauncher ${OPENBUS_HOME}/core/services/accesscontrol/KillAccessControlService.lua "$@"

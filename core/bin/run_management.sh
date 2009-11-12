#!/bin/ksh

if [ -z "${OPENBUS_HOME}" ] ; then
  echo "[ERRO] Variável de ambiente OPENBUS_HOME não definida"
  exit 1
fi

exec ${OPENBUS_HOME}/core/bin/servicelauncher ${OPENBUS_HOME}/core/management/management.lua "$@"

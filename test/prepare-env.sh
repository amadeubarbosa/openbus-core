#!/bin/ksh

if [ -z "${OPENBUS_HOME}" ] ;then
  echo "[ERRO] Variável de ambiente OPENBUS_HOME não definida"
  exit 1
fi 

###############################################################################

. ./test.properties

if [ -z "${host}" ]; then
  host="localhost"
fi
if [ -z "${port}" ]; then
  port=2089
fi
if [ -z "${adminLogin}" ]; then
  adminLogin="admin"
fi
if [ -z "${adminPassword}" ]; then
  adminPassword="admin"
fi
if [ -z "${login}" ]; then
  login="tester"
fi
if [ -z "${certificate}" ]; then
  certificate="teste.crt"
fi
if [ -z "${category}" ]; then
  category="OpenBusTest"
fi
if [ -z "${entity}" ]; then
  entity="TestEntity"
fi

###############################################################################

ADMIN_EXTRAARGS="--host=${host} --port=${port} "
ADMIN_EXTRAARGS="${ADMIN_EXTRAARGS} --login=${adminLogin} "
ADMIN_EXTRAARGS="${ADMIN_EXTRAARGS} --password=${adminPassword} "

${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --add-certificate=${login} --certificate=${certificate}

${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --add-interface="IDL:Ping:1.0"
${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --add-category=${category} --name="OpenBus Test Entities"
${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --add-entity=${entity} --category=${category} --name="entity used in OpenBus demo"
${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --set-authorization=${entity} --grant="IDL:Ping:1.0"

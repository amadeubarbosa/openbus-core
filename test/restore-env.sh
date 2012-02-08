#!/bin/ksh

if [ -z "${OPENBUS_HOME}" ] ;then
  echo "[ERRO] Variável de ambiente OPENBUS_HOME não definida"
  exit 1
fi 

###############################################################################

source ./test.properties

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

${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --del-certificate=${login}

${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --set-authorization=${entity} --revoke="IDL:Ping:1.0"
${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --del-entity=${entity}
${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --del-category=${category}
${OPENBUS_HOME}/bin/busadmin ${ADMIN_EXTRAARGS} --del-interface="IDL:Ping:1.0"


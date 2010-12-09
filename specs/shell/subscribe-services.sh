#!/bin/ksh
showLog()
{
  echo "================================ $1 Output Log ==============================="
  cat $2
  echo
  echo "================================ $1 Error Log ================================"
  cat $3
  echo
  echo "=============================================================================="
}

run_management()
{
  SCRIPT_PARAM="--script="$1
  ${OPENBUS_HOME}/core/bin/run_management.sh ${LOGIN_PARAM} ${ACS_HOST_PARAM} \
    ${ACS_PORT_PARAM} ${SCRIPT_PARAM} --verbose=0
}

run_management_test()
{
  cd ${OPENBUS_HOME}/core/test/management
  run_management test.mgt
  cd -
}

LOGIN=$1
ACS_HOST=$2
ACS_PORT=$3
OPENBUS_PATH=$4

RUN_MANAGEMENT_TEST=$5

if [ -n "${OPENBUS_PATH}" ]; then
  OPENBUS_HOME=${OPENBUS_PATH}
fi

if [ -z "$OPENBUS_HOME" ]; then
  echo "[ERRO] Variavel OPENBUS_HOME não foi definida"
  exit 1
fi

if [ -z "${LOGIN}" ]; then
  echo "[ERRO] Login do administrador não foi definido"
  exit 1
fi

LOGIN_PARAM="--login="${LOGIN}

if [ -n "${ACS_HOST}" ]; then
  ACS_HOST_PARAM="--acs-host="${ACS_HOST}
fi

if [ -n "${ACS_PORT}" ]; then
  ACS_PORT_PARAM="--acs-port="${ACS_PORT}
fi

cd ${OPENBUS_HOME}/specs/management

echo "Iniciando Serviço de Acesso"
ACSOUTFILE=acs.out
ACSERRFILE=acs.err
${OPENBUS_HOME}/core/bin/run_access_control_server.sh >>${ACSOUTFILE} 2>${ACSERRFILE} &
ACSPID=$!
sleep 5

# Verifica se o serviço está no ar.
if ! ( kill -0 ${ACSPID} 2>/dev/null 2>&1 ) ;then
  showLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE}
  exit 1
fi

# Cadastra o ACS e o RS
run_management access_control_service.mgt
run_management registry_service.mgt

echo "Iniciando Serviço de Registro"
RGSOUTFILE=rgs.out
RGSERRFILE=rgs.err
${OPENBUS_HOME}/core/bin/run_registry_server.sh >>${RGSOUTFILE} 2>${RGSERRFILE} &
RGSPID=$!
sleep 5

# Verifica se o serviço está no ar.
if ! ( kill -0 ${RGSPID} 2>/dev/null 2>&1 ) ;then
  showLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  rm -f ${RGSOUTFILE} ${RGSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE}
  kill -9 ${ACSPID}
  exit 1
fi

#Cadastra o SS
run_management session_service.mgt

#Cadastrar os Monitores
run_management monitors.mgt

#Verificar se é necessário cadastrar os testes.
if [ -n "${RUN_MANAGEMENT_TEST}" ]; then
  run_management_test
fi

#Finaliza os serviços
kill -9 ${RGSPID}
kill -9 ${ACSPID}

rm -f ${ACSOUTFILE} ${ACSERRFILE}
rm -f ${RGSOUTFILE} ${RGSERRFILE}


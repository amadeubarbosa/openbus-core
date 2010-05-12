#!/bin/ksh

echo "==============================================================================="
echo
echo "                   TESTE DO SERVIÇO DE CONTROLE DE ACESSO                      "
echo
echo "==============================================================================="

###############################################################################

if [ -z "${WORKSPACE}" ] ;then
  echo "[ERRO] Variável de ambiente WORKSPACE não definida"
  exit 1
fi 

. ${WORKSPACE}/hudson/openbus.sh

###############################################################################

ShowLog() {
  echo "================================ $1 Output Log ==============================="
  cat $2
  echo
  echo "================================ $1 Error Log ================================"
  cat $3
  echo
  echo "=============================================================================="
}

###############################################################################

PIDFILE=${WORKSPACE}/acs.pid
OUTFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
ERRFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err

###############################################################################

echo "Iniciando Serviço de Controle de Acesso"
daemonize -o ${OUTFILE} -e ${ERRFILE} -p ${PIDFILE} ${OPENBUS_HOME}/core/bin/run_access_control_server.sh
sleep 5
PID=`cat ${PIDFILE}`

if ! ( kill -0 ${PID} 1>/dev/null 2>&1 ) ;then
  echo "==============================================================================="
  echo "[ERRO] Falha ao iniciar o Serviço de Controle de Acesso"
  ShowLog "ACS" ${OUTFILE} ${ERRFILE}
  rm -f ${OUTFILE} ${ERRFILE} ${PIDFILE}
  exit 1
fi

###############################################################################

cd ${OPENBUS_HOME}/core/test/lua
cp ${OPENBUS_HOME}/data/certificates/AccessControlService.crt .
echo -e "\n\n\n\n\n\n\n" | ${WORKSPACE}/hudson/genkey.sh TesteBarramento
echo

${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester \
  --add-system=TesteBarramento --description=Teste
${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester \
  --add-deployment=TesteBarramento --description=Teste \
  --certificate=TesteBarramento.crt --system=TesteBarramento

./run_unit_test.sh accesscontrol/TestSuiteAccessControlService.lua
CODE=$?

kill -9 ${PID}

if [ ${CODE} -eq 1 ] ;then
  ShowLog "ACS" ${OUTFILE} ${ERRFILE}
fi

rm -f ${OUTFILE} ${ERRFILE} ${PIDFILE}

exit ${CODE}

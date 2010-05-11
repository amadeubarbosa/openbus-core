#!/bin/ksh

echo "==============================================================================="
echo
echo "                     TESTE DO SERVIÇO DE REGISTRO                              "
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

ACSPIDFILE=${WORKSPACE}/acs.pid
RGSPIDFILE=${WORKSPACE}/rgs.pid
ACSOUTFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
ACSERRFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err
RGSOUTFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
RGSERRFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err

###############################################################################

echo "Iniciando Serviço de Controle de Acesso"
daemonize -o ${ACSOUTFILE} -e ${ACSERRFILE} -p ${ACSPIDFILE} ${OPENBUS_HOME}/core/bin/run_access_control_server.sh
sleep 5
ACSPID=`cat ${ACSPIDFILE}`

if ! ( kill -0 ${ACSPID} 1>/dev/null 2>&1 ) ;then
  echo "==============================================================================="
  echo "[ERRO] Falha ao iniciar o Serviço de Controle de Acesso"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  exit 1
fi

###############################################################################

echo "Iniciando Serviço de Registro"
daemonize -o ${RGSOUTFILE} -e ${RGSERRFILE} -p ${RGSPIDFILE} ${OPENBUS_HOME}/core/bin/run_registry_server.sh
sleep 10
RGSPID=`cat ${RGSPIDFILE}`

if ! ( kill -0 ${RGSPID} 1>/dev/null 2>&1 ) ;then
  echo "==============================================================================="
  echo "[ERRO] Falha ao iniciar o Serviço de Registro"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  kill -9 ${ACSPID}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}
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
${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester \
  --set-authorization=TesteBarramento --grant="IDL:IHello_v1:1.0" --no-strict
${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester \
  --set-authorization=TesteBarramento --grant="IDL:IHello_v2:1.0" --no-strict

./run_unit_test.sh registry/testRegistryService.lua
CODE=$?

kill -9 ${RGSPID}
kill -9 ${ACSPID}

if [ ${CODE} -eq 1 ] ;then
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
fi

rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE} ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}

exit ${CODE}

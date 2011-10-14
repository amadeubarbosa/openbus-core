#!/bin/ksh

echo "==============================================================================="
echo
echo "                    TESTE DO MECANISMO DE GOVERNANÇA                           "
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
SSSPIDFILE=${WORKSPACE}/sss.pid
ACSOUTFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
ACSERRFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err
RGSOUTFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
RGSERRFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err
SSSOUTFILE=${WORKSPACE}/sss-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
SSSERRFILE=${WORKSPACE}/sss-job-${BUILD_NUMBER}-date-${BUILD_ID}.err

###############################################################################

MGT_EXTRAARGS="--login=tester --password=tester"
if [ -n "${ACS_HOST}" ] && [ -n "${ACS_PORT}" ]; then
  # management
  MGT_EXTRAARGS="$MGT_EXTRAARGS --acs-host=${ACS_HOST} "
  MGT_EXTRAARGS="$MGT_EXTRAARGS --acs-port=${ACS_PORT} "
fi

###############################################################################

echo "Iniciando Serviço de Acesso"
daemonize -o ${ACSOUTFILE} -e ${ACSERRFILE} -p ${ACSPIDFILE} ${OPENBUS_HOME}/bin/run_access_control_server.sh
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
daemonize -o ${RGSOUTFILE} -e ${RGSERRFILE} -p ${RGSPIDFILE} ${OPENBUS_HOME}/bin/run_registry_server.sh
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

echo "Iniciando Serviço de Sessão"
daemonize -o ${SSSOUTFILE} -e ${SSSERRFILE} -p ${SSSPIDFILE} ${OPENBUS_HOME}/bin/run_session_server.sh
sleep 10
SSSPID=`cat ${SSSPIDFILE}`

if ! ( kill -0 ${SSSPID} 1>/dev/null 2>&1 ) ;then
  echo "==============================================================================="
  echo "[ERRO] Falha ao iniciar o Serviço de Sessão"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  ShowLog "SSS" ${SSSOUTFILE} ${SSSERRFILE}
  kill -9 ${RGSPID}
  kill -9 ${ACSPID}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}
  rm -f ${SSSOUTFILE} ${SSSERRFILE} ${SSSPIDFILE}
  exit 1
fi

###############################################################################

cd ${OPENBUS_HOME}/test
cp ${OPENBUS_HOME}/data/certificates/AccessControlService.crt .
echo -e "\n\n\n\n\n\n\n" | ${WORKSPACE}/hudson/genkey.sh TesteBarramento
echo -e "\n\n\n\n\n\n\n" | ${WORKSPACE}/hudson/genkey.sh TesteBarramento02
echo

${OPENBUS_HOME}/bin/run_management.sh ${MGT_EXTRAARGS} \
  --add-system=TesteBarramento --description=Teste 
${OPENBUS_HOME}/bin/run_management.sh ${MGT_EXTRAARGS} \
  --add-deployment=TesteBarramento --description=Teste \
  --certificate=TesteBarramento.crt --system=TesteBarramento
${OPENBUS_HOME}/bin/run_management.sh ${MGT_EXTRAARGS} \
  --set-authorization=TesteBarramento --grant="IDL:IHello_v1:1.0" --no-strict
${OPENBUS_HOME}/bin/run_management.sh ${MGT_EXTRAARGS} \
  --set-authorization=TesteBarramento --grant="IDL:IHello_v2:1.0" --no-strict

./run_unit_test.sh management/testManagement.lua
CODE=$?

kill -9 ${SSSPID}
kill -9 ${RGSPID}
kill -9 ${ACSPID}

if [ ${CODE} -eq 1 ] ;then
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  ShowLog "SSS" ${SSSOUTFILE} ${SSSERRFILE}
fi

rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE} ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}
rm -f ${SSSOUTFILE} ${SSSERRFILE} ${SSSPIDFILE}

exit ${CODE}

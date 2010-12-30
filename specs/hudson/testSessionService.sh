#!/bin/ksh

echo "==============================================================================="
echo
echo "                       TESTE DO SERVI�O DE SESS�O                              "
echo
echo "==============================================================================="

###############################################################################

if [ -z "${WORKSPACE}" ] ;then
  echo "[ERRO] Vari�vel de ambiente WORKSPACE n�o definida"
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

echo "Iniciando Servi�o de Controle de Acesso"
daemonize -o ${ACSOUTFILE} -e ${ACSERRFILE} -p ${ACSPIDFILE} ${OPENBUS_HOME}/core/bin/run_access_control_server.sh
sleep 5
ACSPID=`cat ${ACSPIDFILE}`

if ! ( kill -0 ${ACSPID} 1>/dev/null 2>&1 ) ;then
  echo "==============================================================================="
  echo "[ERRO] Falha ao iniciar o Servi�o de Controle de Acesso"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  exit 1
fi

###############################################################################

echo "Iniciando Servi�o de Registro"
daemonize -o ${RGSOUTFILE} -e ${RGSERRFILE} -p ${RGSPIDFILE} ${OPENBUS_HOME}/core/bin/run_registry_server.sh
sleep 10
RGSPID=`cat ${RGSPIDFILE}`

if ! ( kill -0 ${RGSPID} 1>/dev/null 2>&1 ) ;then
  echo "==============================================================================="
  echo "[ERRO] Falha ao iniciar o Servi�o de Registro"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  kill -9 ${ACSPID}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}
  exit 1
fi

###############################################################################

echo "Iniciando Servi�o de Sess�o"
daemonize -o ${SSSOUTFILE} -e ${SSSERRFILE} -p ${SSSPIDFILE} ${OPENBUS_HOME}/core/bin/run_session_server.sh
sleep 10
SSSPID=`cat ${SSSPIDFILE}`

if ! ( kill -0 ${SSSPID} 1>/dev/null 2>&1 ) ;then
  echo "==============================================================================="
  echo "[ERRO] Falha ao iniciar o Servi�o de Sess�o"
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

cd ${OPENBUS_HOME}/core/test
./run_unit_test.sh session/testSessionService.lua
CODE=$?

kill -9 ${SSSPID}
kill -9 ${RGSPID}
kill -9 ${ACSPID}

if [ ${CODE} -eq 1 ] ;then
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  ShowLog "SSS" ${SSSOUTFILE} ${SSSERRFILE}
fi

rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}
rm -f ${SSSOUTFILE} ${SSSERRFILE} ${SSSPIDFILE}

exit ${CODE}

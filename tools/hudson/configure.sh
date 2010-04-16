#!/bin/ksh

echo "==============================================================================="
echo
echo "                         CONFIGURANDO NOVO AMBIENTE                            "
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

echo "==============================================================================="
echo "[INFO] Governan�a: cadastrando servi�os b�sicos"
echo "==============================================================================="

cd ${OPENBUS_HOME}/data/conf

echo -en "\nAccessControlServerConfiguration.administrators = {'tester'}\n" >> \
  AccessControlServerConfiguration.lua
echo -en "AccessControlServerConfiguration.lease = 300\n" >> \
  AccessControlServerConfiguration.lua
echo -en "AccessControlServerConfiguration.oilVerboseLevel = 5\n" >> \
  AccessControlServerConfiguration.lua

echo -en "\nRegistryServerConfiguration.administrators = {'tester'}\n" >> \
  RegistryServerConfiguration.lua
echo -en "RegistryServerConfiguration.oilVerboseLevel = 5\n" >> \
  RegistryServerConfiguration.lua

###############################################################################

# Precisa criar pois pode ser a primeira execu��o
mkdir -p ${OPENBUS_HOME}/data/certificates

# Remove todos o cadastro para criar um novo
rm -f ${OPENBUS_HOME}/data/*.db
rm -f ${OPENBUS_HOME}/data/offers/*
rm -f ${OPENBUS_HOME}/data/credentials/*
rm -f ${OPENBUS_HOME}/data/certificates/*

cd ${OPENBUS_HOME}/data/certificates

for i in AccessControlService RegistryService SessionService ; do
  echo -e "\n\n\n\n\n\n\n" | ${WORKSPACE}/hudson/genkey.sh $i
  echo
done

cp ${OPENBUS_HOME}/data/certificates/*.crt ${OPENBUS_HOME}/tools/management

###############################################################################

ACSPIDFILE=${WORKSPACE}/acs.pid
ACSOUTFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
ACSERRFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err
ACSBIN=${OPENBUS_HOME}/core/bin/run_access_control_server.sh

cd ${OPENBUS_HOME}/core/bin

echo "Iniciando Servi�o de Acesso"
daemonize -o ${ACSOUTFILE} -e ${ACSERRFILE} -p ${ACSPIDFILE} ${ACSBIN}
sleep 10
ACSPID=`cat ${ACSPIDFILE}`

if ! ( kill -0 ${ACSPID} 1>/dev/null 2>&1 ) ;then
  echo "[ERRO] Falha ao iniciar o Servi�o de Controle de Acesso"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  exit 1
fi

###############################################################################

cd ${OPENBUS_HOME}/tools/management

${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester --script=access_control_service.mgt
${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester --script=registry_service.mgt

###############################################################################

RGSPIDFILE=${WORKSPACE}/rgs.pid
RGSOUTFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
RGSERRFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err
RGSBIN=${OPENBUS_HOME}/core/bin/run_registry_server.sh

cd ${OPENBUS_HOME}/core/bin

echo "Iniciando Servi�o de Registro"
daemonize -o ${RGSOUTFILE} -e ${RGSERRFILE} -p ${RGSPIDFILE} ${RGSBIN}
sleep 10
RGSPID=`cat ${RGSPIDFILE}`

if ! ( kill -0 ${RGSPID} 1>/dev/null 2>&1 ) ;then
  kill -9 ${ACSPID}
  echo "[ERRO] Falha ao iniciar o Servi�o de Registro"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}
  exit 1
fi

###############################################################################
# Servi�o de Registro j� deve estar rodando

cd ${OPENBUS_HOME}/tools/management

${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester --script=session_service.mgt

###############################################################################

kill -9 ${RGSPID}
kill -9 ${ACSPID}

rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}

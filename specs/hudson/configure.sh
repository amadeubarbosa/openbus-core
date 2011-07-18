#!/bin/ksh

echo "==============================================================================="
echo
echo "                         CONFIGURANDO NOVO AMBIENTE                            "
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

echo "==============================================================================="
echo "[INFO] Governança: cadastrando serviços básicos"
echo "==============================================================================="

cd ${OPENBUS_HOME}/data/conf

## tratamento de admin, lease e verbose
echo "AccessControlServerConfiguration.administrators = {'tester'}" >> \
  AccessControlServerConfiguration.lua
echo "AccessControlServerConfiguration.lease = 300" >> \
  AccessControlServerConfiguration.lua
echo "AccessControlServerConfiguration.oilVerboseLevel = 5" >> \
  AccessControlServerConfiguration.lua

echo "RegistryServerConfiguration.administrators = {'tester'}" >> \
  RegistryServerConfiguration.lua
echo "RegistryServerConfiguration.oilVerboseLevel = 5" >> \
  RegistryServerConfiguration.lua

MGT_EXTRAARGS=
## tratamento de variações no host/porta do ACS
if [ -n "${ACS_HOST}" ] && [ -n "${ACS_PORT}" ]; then
  # config básica
  echo "AccessControlServerConfiguration.hostName = '${ACS_HOST}'" >> \
  AccessControlServerConfiguration.lua
  echo "AccessControlServerConfiguration.hostPort = ${ACS_PORT}" >> \
  AccessControlServerConfiguration.lua

  echo "RegistryServerConfiguration.accessControlServerHostName = '${ACS_HOST}'" >> \
  RegistryServerConfiguration.lua
  echo "RegistryServerConfiguration.accessControlServerHostPort = ${ACS_PORT}" >> \
  RegistryServerConfiguration.lua

  echo "SessionServerConfiguration.accessControlServerHostName = '${ACS_HOST}'" >> \
  SessionServerConfiguration.lua
  echo "SessionServerConfiguration.accessControlServerHostPort = ${ACS_PORT}" >> \
  SessionServerConfiguration.lua

  # FT
echo "\
ftconfig.hosts.ACS   = { \"corbaloc::${ACS_HOST}:${ACS_PORT}/ACS_v1_05\" }
ftconfig.hosts.ACSIC = { \"corbaloc::${ACS_HOST}:${ACS_PORT}/openbus_v1_05\" }
ftconfig.hosts.LP    = { \"corbaloc::${ACS_HOST}:${ACS_PORT}/LP_v1_05\" }
ftconfig.hosts.FTACS = { \"corbaloc::${ACS_HOST}:${ACS_PORT}/FTACS_v1_05\" }
" >> ACSFaultToleranceConfiguration.lua

  # management
  MGT_EXTRAARGS="$MGT_EXTRAARGS --acs-host=${ACS_HOST} "
  MGT_EXTRAARGS="$MGT_EXTRAARGS --acs-port=${ACS_PORT} "
fi

## tratamento de variações no host/porta do RGS
if [ -n "${RGS_HOST}" ] && [ -n "${RGS_PORT}" ]; then
  # config básica
  echo "RegistryServerConfiguration.registryServerHostName = '${RGS_HOST}'" >> \
  RegistryServerConfiguration.lua
  echo "RegistryServerConfiguration.registryServerHostPort = ${RGS_PORT}" >> \
  RegistryServerConfiguration.lua

  # FT
echo "\
ftconfig.hosts.RS   = { \"corbaloc::${RGS_HOST}:${RGS_PORT}/RS_v1_05\" }
ftconfig.hosts.FTRS = { \"corbaloc::${RGS_HOST}:${RGS_PORT}/FTRS_v1_05\" }
" >> RSFaultToleranceConfiguration.lua
fi

## tratamento de variações no host/porta do SS
if [ -n "${SS_HOST}" ] && [ -n "${SS_PORT}" ]; then
  # config básica
  echo "SessionServerConfiguration.sessionServerHostName = '${SS_HOST}'" >> \
  SessionServerConfiguration.lua
  echo "SessionServerConfiguration.sessionServerHostPort = ${SS_PORT}" >> \
  SessionServerConfiguration.lua
fi

###############################################################################

# Precisa criar pois pode ser a primeira execução
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

cp ${OPENBUS_HOME}/data/certificates/*.crt ${OPENBUS_HOME}/specs/management

###############################################################################

ACSPIDFILE=${WORKSPACE}/acs.pid
ACSOUTFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
ACSERRFILE=${WORKSPACE}/acs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err
ACSBIN=${OPENBUS_HOME}/core/bin/run_access_control_server.sh

cd ${OPENBUS_HOME}/core/bin

echo "Iniciando Serviço de Acesso"
daemonize -o ${ACSOUTFILE} -e ${ACSERRFILE} -p ${ACSPIDFILE} ${ACSBIN}
sleep 10
ACSPID=`cat ${ACSPIDFILE}`

if ! ( kill -0 ${ACSPID} 1>/dev/null 2>&1 ) ;then
  echo "[ERRO] Falha ao iniciar o Serviço de Controle de Acesso"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  exit 1
fi

###############################################################################

cd ${OPENBUS_HOME}/specs/management

${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester --script=access_control_service.mgt ${MGT_EXTRAARGS}
MGTACS_CODE=$?
${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester --script=registry_service.mgt ${MGT_EXTRAARGS}
MGTRGS_CODE=$?

if [ ${MGTACS_CODE} -ne 0 ] -o [ ${MGTRGS_CODE} -ne 0 ] ;then
  kill -9 ${ACSPID}
  echo "[ERRO] Falha ao executar a implantação do Serviço de Acesso ou do Serviço de Registro"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  exit 1
fi

###############################################################################

RGSPIDFILE=${WORKSPACE}/rgs.pid
RGSOUTFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.out
RGSERRFILE=${WORKSPACE}/rgs-job-${BUILD_NUMBER}-date-${BUILD_ID}.err
RGSBIN=${OPENBUS_HOME}/core/bin/run_registry_server.sh

cd ${OPENBUS_HOME}/core/bin

echo "Iniciando Serviço de Registro"
daemonize -o ${RGSOUTFILE} -e ${RGSERRFILE} -p ${RGSPIDFILE} ${RGSBIN}
sleep 10
RGSPID=`cat ${RGSPIDFILE}`

if ! ( kill -0 ${RGSPID} 1>/dev/null 2>&1 ) ;then
  kill -9 ${ACSPID}
  echo "[ERRO] Falha ao iniciar o Serviço de Registro"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}
  exit 1
fi

###############################################################################
# Serviço de Registro já deve estar rodando

cd ${OPENBUS_HOME}/specs/management

${OPENBUS_HOME}/core/bin/run_management.sh --login=tester --password=tester --script=session_service.mgt ${MGT_EXTRAARGS}
MGTSS_CODE=$?

if [ ${MGTSS_CODE} -ne 0 ];then
  echo "[ERRO] Falha ao executar a implantação do Serviço de Sessão"
  ShowLog "ACS" ${ACSOUTFILE} ${ACSERRFILE}
  ShowLog "RGS" ${RGSOUTFILE} ${RGSERRFILE}
  kill -9 ${RGSPID}
  kill -9 ${ACSPID}

  rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
  rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}

  exit 1
fi
###############################################################################

kill -9 ${RGSPID}
kill -9 ${ACSPID}

rm -f ${ACSOUTFILE} ${ACSERRFILE} ${ACSPIDFILE}
rm -f ${RGSOUTFILE} ${RGSERRFILE} ${RGSPIDFILE}

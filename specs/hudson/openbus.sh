###############################################################################
# Compatibilidade: poder rodar sem o Hudson

if [ -z "${BUILD_NUMBER}" ] ;then
  export BUILD_NUMBER=1
  echo "[WARN] Variável de ambiente BUILD_NUMBER não definida: usando '${BUILD_NUMBER}'"
fi 
if [ -z "${BUILD_ID}" ] ;then
  export BUILD_ID=OpenBus
  echo "[WARN] Variável de ambiente BUILD_ID não definida: usando '${BUILD_ID}'"
fi 

###############################################################################
# Limpeza de ambiente e localização do ANT e MAVEN

# reseting the environment
export OPENSSL_HOME=""
export LD_LIBRARY_PATH=""
export LIBRARY_PATH=""
export CPATH=""
export LUA_PATH=""
export LUA_CPATH=""

export M2_HOME="/home/msv/openbus/programas/maven/current"
export M2="${M2_HOME}/bin"
export PATH="${M2}:${HUDSON_HOME}/sbin:${PATH}"

if [ "${TEC_SYSNAME}" == "Linux" ] ;then
  # Disparar o 'uuidd' para evitar prender a porta no ACS
  uuidd -q
  export ANT_HOME="/home/msv/openbus/programas/ant-1.7.1"
  export PATH="${ANT_HOME}/bin:${PATH}"
fi

if [ "${TEC_SYSNAME}" == "SunOS" ] ;then
  export PATH="/home/t/tecgraf/prod/app/openbus/lib/lua5.1/bin/SunOS510:/home/t/tecgraf/bin:${PATH}"
  export JAVA_HOME="/"
fi

###############################################################################
# OpenBus settings

# common path
export OPENBUS_HOME="${WORKSPACE}/install"

. ${WORKSPACE}/trunk/specs/shell/kshrc
###############################################################################

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
# reseting the environment
export OPENSSL_HOME=""
export LD_LIBRARY_PATH=""
export LIBRARY_PATH=""
export CPATH=""
export LUA_PATH=""
export LUA_CPATH=""

if [ "${TEC_SYSNAME}" == "Linux" ] ;then
  # Disparar o 'uuidd' para evitar prender a porta no ACS
  uuidd -q
  export ANT_HOME="/home/msv/openbus/programas/ant-1.7.1"
  export M2_HOME="/home/msv/openbus/programas/maven/current"
  export M2="${M2_HOME}/bin"
  export PATH="${ANT_HOME}/bin:${M2}:${HUDSON_HOME}/sbin:${PATH}"
fi

if [ "${TEC_SYSNAME}" == "SunOS" ] ;then
  #gnu compilers
  export LIBRARY_PATH="/usr/sfw/lib:/usr/local/lib:/usr/ucblib"
  export CPATH="/usr/sfw/include:/usr/local/include:/usr/ucbinclude"
  #sun compilers
  export LDFLAGS="-L/usr/lib -L/usr/sfw/lib -L/usr/local/lib -L/usr/ucblib"
  export CPPFLAGS="-I/usr/include -I/usr/sfw/include -I/usr/local/include -I/usr/ucbinclude"
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/ucblib:/usr/local/lib:/usr/sfw/lib"
  export LD_LIBRARY_PATH_64="/usr/lib/64:/lib/64:/usr/openwin/lib/64:/usr/sfw/lib/64:/usr/local/lib/sparcv9:/usr/ucblib/sparcv9:${LD_LIBRARY_PATH_64}"
  export PATH="${PATH}:/usr/ucb:/usr/sfw/bin:/usr/local/bin:/usr/ccs/bin"
  
  #openbus flags first
  export LDFLAGS="-L${OPENBUS_HOME}/libpath/$TEC_UNAME $LDFLAGS"
  export CFLAGS="-I${OPENBUS_HOME}/incpath/e2fsprogs-1.40.8 -I${OPENBUS_HOME}/incpath/cyrus-sasl-2.1.23 -I${OPENBUS_HOME}/incpath/openldap-2.4.11 -I${OPENBUS_HOME}/incpath/openssl-0.9.9" 
  #tecmake precisa disso porque ele nao funciona com make nativo!
  export TECMAKE_MAKE=/usr/sfw/bin/gmake

  export M2_HOME="/home/msv/openbus/programas/maven/current"
  export M2="${M2_HOME}/bin"
  export PATH="${M2}:${HUDSON_HOME}/sbin:${PATH}"
  export PATH="/home/t/tecgraf/prod/app/openbus/lib/lua5.1/bin/SunOS510:/home/t/tecgraf/bin:${PATH}"
  export JAVA_HOME="/"
fi

###############################################################################
# OpenBus settings

# common path
export OPENBUS_HOME="${WORKSPACE}/install"

export OPENSSL_HOME="${OPENBUS_HOME}/openssl"

export PATH="${OPENBUS_HOME}/bin/${TEC_UNAME}:${OPENBUS_HOME}/bin:${PATH}"

OB_CPATH="${OPENBUS_HOME}/incpath/cxxtest:${OPENBUS_HOME}/incpath/e2fsprogs-1.40.8:${OPENBUS_HOME}/incpath/openldap-2.4.11:${OPENBUS_HOME}/incpath/openssl-0.9.9"
if [ -z ${CPATH} ]; then
  export CPATH="${OB_CPATH}"
else
  export CPATH="${OB_CPATH}:${CPATH}"
fi

OB_LIBRARY_PATH="${OPENBUS_HOME}/libpath/${TEC_UNAME}"
if [ -z ${LIBRARY_PATH} ]; then
  export LIBRARY_PATH="${OB_LIBRARY_PATH}"
else
  export LIBRARY_PATH="${OB_LIBRARY_PATH}:${LIBRARY_PATH}"
fi

OB_LD_LIBRARY_PATH="${OPENBUS_HOME}/libpath/${TEC_UNAME}"
if [ -z ${LD_LIBRARY_PATH} ]; then
  export LD_LIBRARY_PATH="${OB_LD_LIBRARY_PATH}"
else
  export LD_LIBRARY_PATH="${OB_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}"
fi

if [ ${TEC_SYSNAME} == 'Darwin' ]; then
  OB_DYLD_LIBRARY_PATH="${OPENBUS_HOME}/libpath/${TEC_UNAME}"
  if [ -z ${DYLD_LIBRARY_PATH} ]; then
    export DYLD_LIBRARY_PATH="${OB_DYLD_LIBRARY_PATH}"
  else
    export DYLD_LIBRARY_PATH="${OB_DYLD_LIBRARY_PATH}:${DYLD_LIBRARY_PATH}"
  fi
fi

export LUA_PATH="${OPENBUS_HOME}/?.lua;${OPENBUS_HOME}/core/utilities/lua/?.lua;${OPENBUS_HOME}/libpath/lua/5.1/?.lua;${OPENBUS_HOME}/libpath/lua/5.1/?/init.lua;./?.lua;?.lua"
export LUA_CPATH="${OPENBUS_HOME}/libpath/${TEC_UNAME}/lib?.so;./?.so"

###############################################################################

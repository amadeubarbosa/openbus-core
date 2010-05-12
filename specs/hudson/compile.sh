#!/bin/ksh

# Para teste sem o hudson
# Configuração para máquina ferradura
#export WORKSPACE=/local/openbus/hudson/jobs/OpenBus/workspace
# Configuração para máquina delaunay
#export WORKSPACE=/local/openbus/hudson/workspace/SPARC

[ -n "$(which lua5.1)" ] || \
  (echo "ERRO: Não encontrei o binário do lua5.1!" && exit 1)

. ${WORKSPACE}/hudson/openbus.sh

cd ${WORKSPACE}/puts/lua/tools
cp ${WORKSPACE}/hudson/toolsconf.lua .

if [ "${TEC_SYSNAME}" == "Linux" ] ;then
  EXCLUDE="\
    scsmico \
    openbus-mico \
    openbus-demo-hello-mico"
fi

if [ "${TEC_SYSNAME}" == "SunOS" ] ;then
  EXCLUDE="\
    jacorb-2.3.0 \
    luatrace \
    ftc-java \
    scsmico \
    openbus-mico \
    openbus-demo-hello-mico \
    scsorbix \
    openbus-orbix \
    openbus-orbix-doc \
    openbus-orbix-test \
    openbus-demo-hello-orbix  \
    scs-java-ant \
    scs-java \
    openbus-java \
    openbusidl-java \
    openbusapi-java \
    openbusapi-java-doc \
    openbus-demo-hello-java \
    openbus-demo-delegate-java"
fi

lua5.1 console.lua --config=toolsconf.lua --compile -verbose --update --force --exclude="${EXCLUDE}" "$@"

#!/bin/ksh

# Para teste sem o hudson
# Configuração para máquina ferradura
#export WORKSPACE=/local/openbus/hudson/jobs/OpenBus/workspace
# Configuração para máquina delaunay
#export WORKSPACE=/local/openbus/hudson/workspace/SPARC

. ${WORKSPACE}/hudson/openbus.sh

rm -rf ${WORKSPACE}/packs
rm -rf ${WORKSPACE}/lib
rm -rf ${WORKSPACE}/install

cd ${WORKSPACE}/trunk/tools/lua/tools
cp ${WORKSPACE}/hudson/toolsconf.lua .

if [ "${TEC_SYSNAME}" == "Linux" ] ;then
  EXCLUDE="\
    openbus-mico \
    openbus-demo-hello-orbix  \
    scsmico \
    scsorbix \
    openbus-orbix \
    openbus-orbix-doc \
    openbus-orbix-test \
    openbus-demo-hello-mico"
fi

if [ "${TEC_SYSNAME}" == "SunOS" ] ;then
  EXCLUDE="\
    jacorb-2.3.0 \
    luatrace \
    ftc-java \
    openbus-mico \
    openbus-demo-hello-orbix  \
    scsmico \
    scsorbix \
    openbus-orbix \
    openbus-orbix-doc \
    openbus-orbix-test \
    openbus-demo-hello-mico \
    scs-java-ant \
    scs-java \
    openbus-java \
    openbusidl-java \
    openbusapi-java \
    openbusapi-java-doc \
    openbus-demo-hello-java \
    openbus-demo-delegate-java"
fi

lua5.1 console.lua --config=toolsconf.lua --compile -verbose --update --force --exclude="${EXCLUDE}"

PROJNAME=client
APPNAME=${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=config

CPPC=${MICOBIN}/mico-c++
LINKER=${MICOBIN}/mico-ld

DEFINES=${VERBOSE}

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${MICOINC} ${OPENBUS_HOME}/core/utilities/mico ${OPENBUSINC}/scs/mico
LDIR= ${MICOLDIR} 

LIBS= mico2.3.13

SLIB= ${OPENBUSLIB}/libscsmico.a \
      ${OPENBUS_HOME}/core/utilities/mico/lib/${TEC_UNAME}/libopenbus.a

SRC= client.cpp hello.cc


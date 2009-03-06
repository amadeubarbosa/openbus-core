PROJNAME= psdemoMico
APPNAME= demoMico

MICO_HOME=/usr/local

MICOBIN=${MICO_HOME}/bin
MICOINC=${MICO_HOME}/include
MICOLDIR=${MICO_HOME}/lib

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= bin

INCLUDES= ${MICOINC} ${OPENBUS_HOME}/core/utilities/mico ${OPENBUSINC}/scs ${OPENBUSINC}/ftc
LDIR= ${OPENBUSLIB} ${MICOLDIR}

LIBS= dl mico2.3.12 pthread
ifeq "${TEC_SYSNAME}" "SunOS"
LIBS+= socket nsl
endif

SLIB= ${OPENBUS_HOME}/core/utilities/mico/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsmico.a \
      ${OPENBUSLIB}/libftcwooil.a \
      ${OPENBUSLIB}/libluasocket.a

SRC= demoMico.cpp stubs/data_service.cc stubs/project_service.cc

USE_LUA51=YES
USE_STATIC=YES

genstubs:
	mkdir -p stubs
	cd stubs ; ${MICOBIN}/idl --use-quotes --no-paths --typecode --any --poa ${OPENBUS_HOME}/idlpath/core.idl
	cd stubs ; ${MICOBIN}/idl --use-quotes --no-paths --typecode --any --poa ${OPENBUS_HOME}/idlpath/scs.idl
	cd stubs ; ${MICOBIN}/idl --use-quotes --no-paths --typecode --any --poa ${OPENBUS_HOME}/idlpath/data_service.idl
	cd stubs ; ${MICOBIN}/idl --use-quotes --no-paths --typecode --any --poa ${OPENBUS_HOME}/idlpath/project_service.idl

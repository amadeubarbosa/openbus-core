PROJNAME= openbus
LIBNAME= ${PROJNAME}

MICOHOME=${HOME}/tools/mico
#MICOBIN=/usr/local/bin
MICOBIN=${MICOHOME}/idl
MICOINC=${MICOHOME}/include
MICOLDIR=${MICOHOME}/libs

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= ${OPENBUSINC}/scs ${MICOINC}
LDIR= ${OPENBUSLIB} ${MICOLDIR}

LIBS= mico2.3.13 scsmico

SRC= openbus/common/ClientInterceptor.cpp \
     openbus/common/ServerInterceptor.cpp \
     openbus/common/CredentialManager.cpp \
     openbus/common/ORBInitializerImpl.cpp \
     stubs/access_control_service.cc \
     stubs/registry_service.cc \
     stubs/session_service.cc \
     stubs/core.cc \
     stubs/scs.cc

genstubs:
	mkdir -p stubs
	cd stubs ; ${MICOBIN}/idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/idlpath/access_control_service.idl 
	cd stubs ; ${MICOBIN}/idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/idlpath/registry_service.idl
	cd stubs ; ${MICOBIN}/idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/idlpath/session_service.idl
	cd stubs ; ${MICOBIN}/idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/idlpath/core.idl
	cd stubs ; ${MICOBIN}/idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/idlpath/scs.idl
	

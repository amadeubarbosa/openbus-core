PROJNAME=server
APPNAME=${PROJNAME}

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

include config

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/cpp ${OPENBUSINC}/scs 
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS+= it_poa it_art it_ifc it_portable_interceptor crypto

SLIB= ${OPENBUS_HOME}/core/utilities/cpp/lib/${TEC_UNAME}/libopenbusorbix.a \
      ${OPENBUSLIB}/libscsorbix.a

USE_LUA51= YES

SRC= server.cpp \
     stubs/helloC.cxx \
     stubs/helloS.cxx

genstubs:
	mkdir -p stubs
	cd stubs ; ${ORBIXBIN}/idl -base -poa ../../idl/hello.idl


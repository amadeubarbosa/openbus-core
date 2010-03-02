PROJNAME=server
APPNAME=${PROJNAME}

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=config

ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/cpp ${OPENBUSINC}/scs
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS= it_poa it_art it_ifc it_portable_interceptor crypto

SLIB= ${OPENBUS_HOME}/core/utilities/cpp/lib/${TEC_UNAME}/libopenbusorbix.a \
      ${OPENBUSLIB}/libscsorbix.a

SRC= server.cpp \
     stubs/helloC.cxx \
     stubs/helloS.cxx

genstubs:
	mkdir -p stubs
	cd stubs ; ${ORBIXBIN}/idl -base -poa ../../idl/hello.idl


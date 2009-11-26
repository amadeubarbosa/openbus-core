PROJNAME=server
APPNAME=${PROJNAME}

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=config

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/orbix ${OPENBUSINC}/scs
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS= it_poa it_art it_ifc it_portable_interceptor crypto

SLIB= ${OPENBUS_HOME}/core/utilities/orbix/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsorbix.a

SRC= server.cpp \
     stubs/helloC.cxx \
     stubs/helloS.cxx

genstubs:
	mkdir -p stubs
	cd stubs ; ${ORBIXBIN}/idl -base -poa ../../idl/hello.idl


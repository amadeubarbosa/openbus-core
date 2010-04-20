PROJNAME= ACSTester
APPNAME= acs

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

include ../config

ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
  LFLAGS= $(CPPFLAGS) -xildoff
endif

INCLUDES= . \
  ${ORBIXINC} \
  ${OPENBUS_HOME}/core/utilities/cpp \
  ${OPENBUSINC}/scs \
  ${OPENBUSINC}/cxxtest \
  ${OPENBUSINC}/openssl-0.9.9
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS= crypto it_poa it_art it_ifc it_portable_interceptor

SLIB= ${OPENBUS_HOME}/core/utilities/cpp/lib/${TEC_UNAME}/libopenbusorbix.a \
      ${OPENBUSLIB}/libscsorbix.a

USE_LUA51= YES

SRC= runner.cpp

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp ACSTestSuite.cpp


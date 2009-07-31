PROJNAME= ACSTester
APPNAME= acs

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=../config

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

INCLUDES= . \
  ${ORBIXINC} \
  ${OPENBUS_HOME}/core/utilities/orbix \
  ${OPENBUSINC}/scs/orbix \
  ${OPENBUSINC}/cxxtest \
  ${OPENBUSINC}/openssl-0.9.9
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS= crypto it_poa it_art it_ifc it_portable_interceptor

SLIB= ${OPENBUS_HOME}/core/utilities/orbix/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsorbix.a

SRC= runner.cpp

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp ACSTestSuite.cpp


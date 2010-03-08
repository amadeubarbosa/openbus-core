PROJNAME= RGSTester
APPNAME= rgs

DEFINES=SCS_MICO
DEFINES+=OPENBUS_MICO

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=../config

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

INCLUDES= . \
  ${MICO_INC} \
  ${OPENBUS_HOME}/core/utilities/cpp \
  ${OPENBUSINC}/scs \
  ${OPENBUSINC}/cxxtest \
  ${OPENBUSINC}/openssl-0.9.9

LDIR= ${MICO_LIB} \
  ${OPENBUSLIB}

LIBS= crypto mico2.3.11 dl

SLIB= ${OPENBUS_HOME}/core/utilities/cpp/lib/${TEC_UNAME}/libopenbusmico.a \
  ${OPENBUSLIB}/libscsmico.a

SRC= runner.cpp \
     RGSTestSuite.cpp

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp RGSTestSuite.cpp

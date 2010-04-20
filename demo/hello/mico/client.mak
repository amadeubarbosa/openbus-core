PROJNAME=client
APPNAME=${PROJNAME}

DEFINES=SCS_MICO
DEFINES+=OPENBUS_MICO

#Descomente as duas linhas abaixo para o uso em Valgrind.
DBG=YES
CPPFLAGS= -fno-inline

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=config

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . \
  stubs \
  ${MICO_INC} \
  ${OPENBUS_HOME}/core/utilities/cpp \
  ${OPENBUSINC}/scs

LDIR= ${MICO_LIB} ${OPENBUSLIB}

LIBS= mico2.3.11 dl crypto pthread

SLIB= ${OPENBUS_HOME}/core/utilities/cpp/lib/${TEC_UNAME}/libopenbusmico.a \
      ${OPENBUSLIB}/libscsmico.a

USE_LUA51= YES

SRC= client.cpp \
     stubs/hello.cc 


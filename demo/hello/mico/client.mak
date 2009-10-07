PROJNAME=client
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

INCLUDES= . \
  stubs \
  ${MICO_INC} \
  ${OPENBUS_HOME}/core/utilities/mico \
  ${OPENBUS_HOME}/core/utilities/mico/stubs \
  ${OPENBUSINC}/scs/mico

LDIR= ${MICO_LDIR} ${OPENBUSLIB}

LIBS= mico2.3.13 dl crypto pthread

SLIB= ${OPENBUS_HOME}/core/utilities/mico/lib/${TEC_UNAME}/libopenbus_mico.a \
      ${OPENBUSLIB}/libscsmico.a

SRC= client.cpp \
     stubs/hello.cc 


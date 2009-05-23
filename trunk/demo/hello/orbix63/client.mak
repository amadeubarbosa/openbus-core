PROJNAME=client
APPNAME=${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=config

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

DEFINES=VERBOSE

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/orbix ${OPENBUSINC}/scs/orbix
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS= it_poa it_art it_ifc it_portable_interceptor crypto

SLIB= ${OPENBUS_HOME}/core/utilities/orbix/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsorbix.a

SRC= client.cpp \
     stubs/helloC.cxx


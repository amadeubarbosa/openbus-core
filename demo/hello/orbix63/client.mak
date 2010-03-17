PROJNAME=client
APPNAME=${PROJNAME}

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

include config

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/orbix ${OPENBUSINC}/scs/orbix
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS+= it_poa it_art it_ifc it_portable_interceptor crypto

SLIB= ${OPENBUS_HOME}/core/utilities/orbix/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsorbix.a

SRC= client.cpp \
     stubs/helloC.cxx


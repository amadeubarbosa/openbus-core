PROJNAME=server
APPNAME=${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=config

CPPFLAGS= -g3 -mtune=pentium3 -march=i586 -pipe -D_REENTRANT -Wno-sign-compare
LFLAGS= $(CPPFLAGS) -rdynamic -L/usr/local/lib -Wl,-t -lpthread -lrt

CPPC=g++-3.4

DEFINES=${VERBOSE}

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/orbix ${OPENBUSINC}/scs
LDIR= ${ORBIXLDIR} 

LIBS= it_poa it_art it_ifc it_portable_interceptor

SLIB= ${OPENBUSLIB}/libscsorbix.a \
      ${OPENBUS_HOME}/core/utilities/orbix/lib/${TEC_UNAME}/libopenbus.a

SRC= server.cpp helloC.cxx helloS.cxx


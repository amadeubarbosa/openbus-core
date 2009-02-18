PROJNAME= ACSTester
APPNAME= acs

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=../config

CPPFLAGS= -g3 -mtune=pentium3 -march=i586 -pipe -D_REENTRANT -Wno-sign-compare
LFLAGS= $(CPPFLAGS) -rdynamic -L/usr/local/lib -Wl,-t -lpthread -lrt

CPPC=g++

TARGETROOT=bin
OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/orbix ${OPENBUSINC}/scs ${OPENBUSINC}/cxxtest
LDIR= ${ORBIXLDIR} 

LIBS= it_poa it_art it_ifc it_portable_interceptor

SLIB= ${OPENBUS_HOME}/core/utilities/orbix/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsorbix.a

SRC= runner.cpp

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp ACSTestSuite.cpp


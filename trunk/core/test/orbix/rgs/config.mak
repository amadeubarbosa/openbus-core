PROJNAME= RGSTester
APPNAME= rgs

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

EXTRA_CONFIG=../config

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif
#CPPFLAGS= -g3 -pipe -D_REENTRANT -Wno-sign-compare
#LFLAGS= $(CPPFLAGS) -rdynamic -L/usr/local/lib -Wl,-t -lpthread -lrt
#CPPC=g++

#TARGETROOT=bin
#OBJROOT=obj

INCLUDES= . ${ORBIXINC} ${OPENBUS_HOME}/core/utilities/orbix ${OPENBUSINC}/scs/orbix ${OPENBUSINC}/cxxtest ${OPENBUSINC}/openssl-0.9.9
LDIR= ${ORBIXLDIR} 

LIBS= crypto it_poa it_art it_ifc it_portable_interceptor

SLIB= ${OPENBUSLIB}/libscsorbix.a \
      ${OPENBUS_HOME}/core/utilities/orbix/lib/${TEC_UNAME}/libopenbus.a

SRC= runner.cpp \
     RGSTestSuite.cpp

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp RGSTestSuite.cpp


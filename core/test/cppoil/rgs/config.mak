PROJNAME= RGSTester
APPNAME= rgs

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

INCLUDES= ${OPENBUS_HOME}/core/utilities/cppoil ${OPENBUSINC}/cxxtest ${OPENBUSINC}/tolua5.1 ${OPENBUSINC}/scs/cppoil
LDIR= ${OPENBUSLIB}

LIBS= dl
ifeq "${TEC_SYSNAME}" "SunOS"
LIBS+= socket nsl
endif

SLIB= ${OPENBUS_HOME}/core/utilities/cppoil/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsoil.a \
      ${OPENBUSLIB}/liboilall.a \
      ${OPENBUSLIB}/libscsall.a \
      ${OPENBUSLIB}/libluasocket.a \
      ${OPENBUSLIB}/libtolua5.1.a

SRC= runner.cpp \
     hellobind.cpp

USE_LUA51=YES
USE_STATIC=YES
NO_SCRIPTS=YES

ifeq "${TEC_SYSNAME}" "Linux"
	LFLAGS = -Wl,-E
endif

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp RGSTestSuite.cpp


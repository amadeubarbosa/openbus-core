PROJNAME= ACSTester
APPNAME= acs

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

INCLUDES= ${OPENBUS_HOME}/core/utilities/cppoil ${OPENBUSINC}/cxxtest ${OPENBUSINC}/tolua-5.1b ${OPENBUSINC}/scs
LDIR= ${OPENBUSLIB}

LIBS= dl 

SLIB= ${OPENBUS_HOME}/core/utilities/cppoil/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsoil.a \
      ${OPENBUSLIB}/liboilall.a \
      ${OPENBUSLIB}/libluasocket.a \
      ${OPENBUSLIB}/libtolua.a

SRC= runner.cpp 

USE_LUA51=YES
USE_STATIC=YES
NO_SCRIPTS=YES

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp ACSTestSuite.cpp


PROJNAME= PSTester
APPNAME= ps

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OBJROOT= obj
TARGETROOT= lib

INCLUDES= ${OPENBUS_HOME}/core/utilities/cppoil ${OPENBUSINC}/cxxtest ${OPENBUSINC}/tolua-5.1b ${OPENBUSINC}/scs
LDIR= ${OPENBUSLIB}

LIBS= dl

SLIB= ${OPENBUS_HOME}/core/utilities/cppoil/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsoil.a \
      ${OPENBUSLIB}/liboilall.a \
      ${OPENBUSLIB}/libluasocket.a \
      ${OPENBUSLIB}/libtolua5.1.a

SRC= runner.cpp ../IProjectService.cpp

USE_LUA51=YES
USE_STATIC=YES

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp PSTestSuite.cpp


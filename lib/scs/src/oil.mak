PROJNAME= scsoil
LIBNAME= ${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

INCLUDES= ../include ${OPENBUSINC}/tolua5.1

LIBS= dl

SLIB= ${OPENBUSLIB}/libtolua5.1.a

SRC= IComponentOil.cpp

USE_LUA51=YES
USE_STATIC=YES


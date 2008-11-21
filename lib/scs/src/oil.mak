PROJNAME= scsoil
LIBNAME= ${PROJNAME}

OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

INCLUDES= ../include ${OPENBUSINC}/tolua5.1
LDIR= ${OPENBUSLIB}

LIBS= dl tolua5.1

SRC= IComponentOil.cpp ComponentBuilderOil.cpp

USE_LUA51=YES
USE_STATIC=YES


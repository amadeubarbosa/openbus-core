PROJNAME= psdemo
APPNAME= demo

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= bin

INCLUDES= ${OPENBUS_HOME}/core/utilities/cppoil ${OPENBUSINC}/tolua-5.1b ${OPENBUSINC}/scs ${OPENBUSINC}/ftc
LDIR= ${OPENBUSLIB}

LIBS= dl ftc

SLIB= ${OPENBUS_HOME}/core/utilities/cppoil/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libscsoil.a \
      ${OPENBUSLIB}/liboilall.a \
      ${OPENBUSLIB}/libluasocket.a \
      ${OPENBUSLIB}/libtolua5.1.a

SRC= demo.cpp ../IProjectService.cpp

USE_LUA51=YES
USE_STATIC=YES

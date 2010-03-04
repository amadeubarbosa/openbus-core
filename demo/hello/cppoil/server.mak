PROJNAME= server
APPNAME= ${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OBJROOT= obj
TARGETROOT= bin

INCLUDES= ${OPENBUS_HOME}/core/utilities/cppoil ${OPENBUSINC}/tolua5.1 ${OPENBUSINC}/scs/cppoil
LDIR= ${OPENBUSLIB} ${OPENBUS_HOME}/core/utilities/cppoil/lib/${TEC_UNAME}

LIBS= dl
ifeq "${TEC_SYSNAME}" "SunOS"
LIBS+= socket nsl
endif

SLIB= ${OPENBUS_HOME}/core/utilities/cppoil/lib/${TEC_UNAME}/libopenbus.a \
      ${OPENBUSLIB}/libftc.a \
      ${OPENBUSLIB}/libscsoil.a \
      ${OPENBUSLIB}/liboilall.a \
      ${OPENBUSLIB}/libscsall.a \
      ${OPENBUSLIB}/libluasocket.a \
      ${OPENBUSLIB}/libtolua5.1.a

SRC= server.cpp hello.cpp

USE_LUA51=YES
USE_STATIC=YES

ifeq "${TEC_SYSNAME}" "Linux"
	LFLAGS = -Wl,-E
endif

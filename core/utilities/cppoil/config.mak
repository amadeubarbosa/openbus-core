PROJNAME= openbus
LIBNAME= ${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= ${OPENBUSINC}/tolua-5.1b ${OPENBUSINC}/oil04 ${OPENBUSINC}/luasocket2 ${OPENBUSINC}/scs
LDIR= ${OPENBUSLIB}

LIBS= scsoil

SLIB= ${OPENBUSLIB}/liboilall.a \
      ${OPENBUSLIB}/libluasocket.a \
      ${OPENBUSLIB}/libtolua.a

SRC= common/ClientInterceptor.cpp \
     common/CredentialManager.cpp \
     auxiliar.c \
     openbus.cpp \
     stubs/IAccessControlService.cpp \
     stubs/IRegistryService.cpp \
     stubs/ISessionService.cpp

USE_LUA51=YES
USE_STATIC=YES

precompile:
	lua5.1 precompiler.lua -f auxiliar -p auxiliar openbus.lua


PROJNAME= openbus
LIBNAME= ${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

PRECMP_DIR= obj/${TEC_UNAME}

${PRECMP_DIR}/auxiliar.c ${PRECMP_DIR}/auxiliar.h:
	lua5.1 precompiler.lua -f auxiliar -d ${PRECMP_DIR} -p auxiliar openbus.lua

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= ${OPENBUSINC}/tolua-5.1b ${OPENBUSINC}/oil04 ${OPENBUSINC}/luasocket2 ${OPENBUSINC}/scs ${PRECMP_DIR}
LDIR= ${OPENBUSLIB}

LIBS= scsoil oilall luasocket tolua5.1

SRC= common/ClientInterceptor.cpp \
     common/CredentialManager.cpp \
     auxiliar.c \
     openbus.cpp \
     stubs/IAccessControlService.cpp \
     stubs/IRegistryService.cpp \
     stubs/ISessionService.cpp \
     stubs/IDataService.cpp

USE_LUA51=YES
USE_STATIC=YES


EXTRA_CONFIG=config

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

PROJNAME= openbus
LIBNAME= ${PROJNAME}

OBJROOT= ../../../obj/cpp
TARGETROOT= ../../../lib/cpp

INCLUDES=../../../include ${TOLUA_INC}

SRC= common/ClientInterceptor.cpp common/CredentialManager.cpp auxiliar.c openbus.cpp scs/core/IComponent.cpp \
services/IAccessControlService.cpp services/IRegistryService.cpp services/ISessionService.cpp

USE_LUA51=YES
USE_STATIC=YES

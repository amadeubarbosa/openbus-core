PROJNAME= openbus
LIBNAME= ${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

LUABIN=     lua5.1

PRECMP_DIR=   obj/$(TEC_UNAME)
PRECMP_LUA=   precompiler.lua
PRECMP_FLAGS= -d $(PRECMP_DIR) -f auxiliar -p auxiliar

$(PRECMP_DIR)/auxiliar.c $(PRECMP_DIR)/auxiliar.h: openbus.lua
	$(LUABIN) $(PRECMP_LUA) $(PRECMP_FLAGS) $< 

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= ${OPENBUSINC}/tolua-5.1b ${OPENBUSINC}/oil04 ${OPENBUSINC}/luasocket2 ${OPENBUSINC}/scs ${PRECMP_DIR}
LDIR= ${OPENBUSLIB}

LIBS= scsoil oilall scsall luasocket tolua5.1

SRC= ${PRECMP_DIR}/auxiliar.c \
     common/ClientInterceptor.cpp \
     common/ServerInterceptor.cpp \
     common/CredentialManager.cpp \
     openbus.cpp \
     stubs/IAccessControlService.cpp \
     stubs/IRegistryService.cpp \
     stubs/ISessionService.cpp \
     stubs/IDataService.cpp

USE_LUA51=YES
NO_LUALINK=YES

PROJNAME= OpenBus
APPNAME= rgs.bin

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
LUAPATH = '${OPENBUS_HOME}/lib/lua/5.1/?.lua;${OPENBUS_HOME}/src/lua/openbus/?.lua;../../?.lua;'

OPENBUSLIB= ${OPENBUS_HOME}/lib
OPENBUSINC= ${OPENBUS_HOME}/include

PRECMP_DIR= ../obj/$(APPNAME)/${TEC_UNAME}
PRECMP_LUA= ${OPENBUS_HOME}/lib/lua/5.1/precompiler.lua
PRECMP_FLAGS= -p REGISTRY_SERVER -o rgs -l ${LUAPATH} -d ${PRECMP_DIR} -n

PRELOAD_LUA= ${OPENBUS_HOME}/lib/lua/5.1/preloader.lua
PRELOAD_FLAGS= -p REGISTRY_SERVER -o rgspreloaded -d ${PRECMP_DIR}

RGS_MODULES=$(addprefix core.services.registry.,\
        OffersDB \
        RegistryService \
        RegistryServer )

RGS_MODULES+= core.services.faulttolerance.FaultTolerantService

RGS_LUA= \
$(addprefix ../../, \
  $(addsuffix .lua, \
    $(subst .,/, $(RGS_MODULES))))

${PRECMP_DIR}/rgs.c: ${RGS_LUA}
	$(LUABIN) $(LUA_FLAGS) $(PRECMP_LUA)   $(PRECMP_FLAGS) $(RGS_MODULES)

${PRECMP_DIR}/rgspreloaded.c: ${PRECMP_DIR}/rgs.c
	$(LUABIN) $(LUA_FLAGS) $(PRELOAD_LUA)  $(PRELOAD_FLAGS) -i ${PRECMP_DIR} rgs.h

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

SRC= ${PRECMP_DIR}/rgs.c ${PRECMP_DIR}/rgspreloaded.c registry.c

INCLUDES= . \
        ${PRECMP_DIR} \
        ${OPENBUSINC}/oil-0.5.0 \
        ${OPENBUSINC}/luasocket2 \
        ${OPENBUSINC}/luafilesystem \
        ${OPENBUSINC}/luuid \
        ${OPENBUSINC}/scs \
        ${OPENBUSINC}/openbus/lua

LDIR += ${OPENBUSLIB}

USE_LUA51=YES
NO_SCRIPTS=YES
USE_NODEPEND=YES

#############################
# Usa bibliotecas dinâmicas #
#############################

LIBS = oilall scsall luasocket lfs luuid luaopenbus
LIBS += dl
ifneq "$(TEC_SYSNAME)" "Darwin"
	LIBS += uuid
endif
ifeq "$(TEC_SYSNAME)" "Linux"
	LFLAGS = -Wl,-E
endif
ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CFLAGS= -g -KPIC -mt -D_REENTRANT
  ifeq ($(TEC_WORDSIZE), TEC_64)
    CFLAGS+= -m64
  endif
  LFLAGS= $(CFLAGS) -xildoff
  LIBS += rt resolv
endif

.PHONY: clean-custom
clean-custom-obj:
	rm -f ${PRECMP_DIR}/*.c
	rm -f ${PRECMP_DIR}/*.h

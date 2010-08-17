PROJNAME= OpenBus
APPNAME= ss

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
LUAPATH = '${OPENBUS_HOME}/libpath/lua/5.1/?.lua;../../?.lua;'

OPENBUSLIB= ${OPENBUS_HOME}/libpath/${TEC_UNAME} 
OPENBUSINC= ${OPENBUS_HOME}/incpath

PRECMP_DIR= ../obj/ss/${TEC_UNAME}
PRECMP_LUA= ${OPENBUS_HOME}/libpath/lua/5.1/precompiler.lua
PRECMP_FLAGS= -p SESSION_SERVICE -o ss -l ${LUAPATH} -d ${PRECMP_DIR} -n

PRELOAD_LUA= ${OPENBUS_HOME}/libpath/lua/5.1/preloader.lua
PRELOAD_FLAGS= -p SESSION_SERVICE -o sspreloaded -d ${PRECMP_DIR}

SS_MODULES= $(addprefix core.services.session.,\
        Session \
        SessionServiceComponent \
        SessionService \
        SessionServer )

SS_LUA= \
$(addprefix ../../, \
  $(addsuffix .lua, \
    $(subst .,/, $(SS_MODULES))))

${PRECMP_DIR}/ss.c: ${SS_LUA}
	$(LUABIN) $(LUA_FLAGS) $(PRECMP_LUA)   $(PRECMP_FLAGS) $(SS_MODULES) 

${PRECMP_DIR}/sspreloaded.c: ${PRECMP_DIR}/ss.c
	$(LUABIN) $(LUA_FLAGS) $(PRELOAD_LUA)  $(PRELOAD_FLAGS) -i ${PRECMP_DIR} ss.h

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

SRC= ${PRECMP_DIR}/ss.c ${PRECMP_DIR}/sspreloaded.c session.c

INCLUDES= . \
        ${PRECMP_DIR} \
        ${OPENBUSINC}/oil-0.5-beta-obv \
        ${OPENBUSINC}/luasocket2 \
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

LIBS = oilall scsall luasocket luuid luaopenbus
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
  LIBS += rt
endif

.PHONY: clean-custom
clean-custom-obj:
	rm -f ${PRECMP_DIR}/*.c
	rm -f ${PRECMP_DIR}/*.h

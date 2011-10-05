PROJNAME= OpenBus
APPNAME= acs.bin

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
LUAPATH = '${OPENBUS_HOME}/lib/lua/5.1/?.lua;${OPENBUS_HOME}/src/lua/openbus/?.lua;../../?.lua;'

OPENBUSLIB= ${OPENBUS_HOME}/lib
OPENBUSINC= ${OPENBUS_HOME}/include

PRECMP_DIR= ../obj/$(APPNAME)/${TEC_UNAME}
PRECMP_LUA= ${OPENBUS_HOME}/lib/lua/5.1/precompiler.lua
PRECMP_FLAGS= -p ACCESSCONTROL_SERVER -o acs -l ${LUAPATH} -d ${PRECMP_DIR} -n

PRELOAD_LUA= ${OPENBUS_HOME}/lib/lua/5.1/preloader.lua
PRELOAD_FLAGS= -p ACCESSCONTROL_SERVER -o acspreloaded -d ${PRECMP_DIR}

ACS_MODULES=$(addprefix core.services.accesscontrol.,\
	CertificateDB \
	CredentialDB \
	LoginPasswordValidator \
	TestLoginPasswordValidator \
	ActiveDirectoryLoginValidator \
	AccessControlService \
	AccessControlServer )

ACS_MODULES+= core.services.faulttolerance.FaultTolerantService

ACS_LUA= \
$(addprefix ../../, \
  $(addsuffix .lua, \
    $(subst .,/, $(ACS_MODULES))))

${PRECMP_DIR}/acs.c: ${ACS_LUA}
	$(LUABIN) $(LUA_FLAGS) $(PRECMP_LUA)   $(PRECMP_FLAGS) $(ACS_MODULES) 

${PRECMP_DIR}/acspreloaded.c: ${PRECMP_DIR}/acs.c
	$(LUABIN) $(LUA_FLAGS) $(PRELOAD_LUA)  $(PRELOAD_FLAGS) -i ${PRECMP_DIR} acs.h

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

SRC= ${PRECMP_DIR}/acs.c ${PRECMP_DIR}/acspreloaded.c accesscontrol.c

INCLUDES= . \
        ${PRECMP_DIR} \
        ${OPENBUSINC}/oil-0.5.0 \
        ${OPENBUSINC}/luasocket2 \
        ${OPENBUSINC}/luafilesystem \
        ${OPENBUSINC}/luuid \
        ${OPENBUSINC}/lce \
        ${OPENBUSINC}/lualdap-1.1.0 \
        ${OPENBUSINC}/scs \
        ${OPENBUSINC}/openbus/lua

LDIR += ${OPENBUSLIB}

USE_LUA51=YES
NO_SCRIPTS=YES
USE_NODEPEND=YES

#############################
# Usa bibliotecas dinâmicas #
#############################

LIBS = oilall scsall luasocket lfs luuid lce lualdap luaopenbus
LIBS += dl crypto ldap
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

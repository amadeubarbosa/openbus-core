PROJNAME= OpenBus
APPNAME= openbus

USE_LUA51= YES
USE_NODEPEND= YES

SRC= \
	launcher.c \
	coreservlibs.c

SRCLUADIR= ../lua
SRCLUA= \
	openbus/core/Access.lua \
	openbus/core/bin/openbus.lua \
	openbus/core/idl/makeaux.lua \
	openbus/core/idl/parsed.lua \
	openbus/core/idl.lua \
	openbus/core/legacy/AccessControlService.lua \
	openbus/core/legacy/idl.lua \
	openbus/core/legacy/parsed.lua \
	openbus/core/legacy/RegistryService.lua \
	openbus/core/services/LoginDB.lua \
	openbus/core/services/AccessControl.lua \
	openbus/core/services/OfferIndex.lua \
	openbus/core/services/OfferRegistry.lua \
	openbus/core/services/passwordvalidator/LDAP.lua \
	openbus/core/util/database.lua \
	openbus/core/util/logger.lua \
	openbus/core/util/messages.lua \
	openbus/core/util/server.lua \
	openbus/core/util/sysex.lua \
	openbus/util/messages.lua \
	openbus/util/oo.lua

LIBS= \
	dl \
	crypto \
	ldap \
	luuid \
	lce \
	lpw \
	lfs \
	lualdap \
	luasocket \
	oilall \
	scsall

LOHPACK= coreserv.loh

DEFINES= OPENBUS_PROG=\"openbus\"

OPENBUSINC= ${OPENBUS_HOME}/incpath
OPENBUSLIB= ${OPENBUS_HOME}/libpath/$(TEC_UNAME)
OPENBUSIDLv20= ../../idl
#OPENBUSIDLv20= ${OPENBUS_HOME}/idlpath/v2_00
OPENBUSIDLv15= ${OPENBUS_HOME}/idlpath/v1_05

INCLUDES+= . $(SRCLUADIR) \
	${OPENBUSINC}/luuid \
	${OPENBUSINC}/lce \
	${OPENBUSINC}/lpw \
	${OPENBUSINC}/luafilesystem \
	${OPENBUSINC}/lualdap-1.0.1 \
	${OPENBUSINC}/luasocket2 \
	${OPENBUSINC}/oil-0.5.0 \
	${OPENBUSINC}/scs
LDIR+= ${OPENBUSLIB}

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

openbus/core/idl/parsed.lua: ${OPENBUSIDLv20}/access_control.idl \
                             ${OPENBUSIDLv20}/offer_registry.idl
	$(LUABIN) ${OIL_HOME}/lua/idl2lua.lua -o $(SRCLUADIR)/$@ $^

PROJNAME= busservices
APPNAME= $(PROJNAME)

#apenas necessario pela compatilibidade com OpenBus 1.5
#para gerar o modulo Lua openbus.core.legacy.parsed
OPENBUSIDL= ${OPENBUS_HOME}/idl/v1_05
OPENBUSINC= ${OPENBUS_HOME}/include
OPENBUSLIB= ${OPENBUS_HOME}/lib

SRC= \
	launcher.c \
	coreservlibs.c \
	$(PRELOAD_DIR)/coreservices.c

LUADIR= ../lua
LUASRC= \
	$(LUADIR)/openbus/core/legacy/AccessControlService.lua \
	$(LUADIR)/openbus/core/legacy/idl.lua \
	$(LUADIR)/openbus/core/legacy/parsed.lua \
	$(LUADIR)/openbus/core/legacy/RegistryService.lua \
	$(LUADIR)/openbus/core/services/Access.lua \
	$(LUADIR)/openbus/core/services/AccessControl.lua \
	$(LUADIR)/openbus/core/services/LoginDB.lua \
	$(LUADIR)/openbus/core/services/main.lua \
	$(LUADIR)/openbus/core/services/messages.lua \
	$(LUADIR)/openbus/core/services/OfferIndex.lua \
	$(LUADIR)/openbus/core/services/OfferRegistry.lua \
	$(LUADIR)/openbus/core/services/passwordvalidator/LDAP.lua

IDL= \
	$(OPENBUSIDL)/access_control_service.idl \
	$(OPENBUSIDL)/registry_service.idl \
	$(OPENBUSIDL)/fault_tolerance.idl

include ${OIL_HOME}/openbus/base.mak

LIBS= \
	dl crypto ldap \
	lua5.1 luuid lce lfs lualdap luavararg luastruct luasocket \
	loop luatuple luacoroutine luacothread luainspector luaidl oil luascs luaopenbus

DEFINES= \
	OPENBUS_MAIN=\"openbus.core.services.main\" \
	OPENBUS_PROGNAME=\"$(APPNAME)\"

INCLUDES+= . $(SRCLUADIR) \
	$(OPENBUSINC)/luuid \
	$(OPENBUSINC)/lce \
	$(OPENBUSINC)/lpw \
	$(OPENBUSINC)/luafilesystem \
	$(OPENBUSINC)/lualdap-1.1.0 \
	$(OPENBUSINC)/luavararg \
	$(OPENBUSINC)/luastruct \
	$(OPENBUSINC)/luasocket2 \
	$(OPENBUSINC)/loop \
	$(OPENBUSINC)/oil \
	$(OPENBUSINC)/scs/lua \
	$(OPENBUSINC)/openbus/lua
LDIR+= $(OPENBUSLIB)

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

$(LUADIR)/openbus/core/legacy/parsed.lua: $(IDL2LUA) $(IDL)
	$(OILBIN) $(IDL2LUA) -I $(OPENBUSIDL) -o $@ $(IDL)

$(PRELOAD_DIR)/coreservices.c $(PRELOAD_DIR)/coreservices.h: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h coreservices.h \
	                           -o coreservices.c \
	                           $(LUASRC)

coreservlibs.c: $(PRELOAD_DIR)/coreservices.h

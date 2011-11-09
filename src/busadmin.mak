PROJNAME= busadmin
APPNAME= $(PROJNAME)

OPENBUSINC= ${OPENBUS_HOME}/include
OPENBUSLIB= ${OPENBUS_HOME}/lib

SRC= \
	launcher.c \
	adminlibs.c \
	$(PRELOAD_DIR)/coreadmin.c

LUADIR= ../lua
LUASRC= \
	$(LUADIR)/openbus/core/legacy/AccessControlService.lua \
	$(LUADIR)/openbus/core/legacy/idl.lua \
	$(LUADIR)/openbus/core/legacy/parsed.lua \
	$(LUADIR)/openbus/core/legacy/RegistryService.lua \
	$(LUADIR)/openbus/core/admin/main.lua \
	$(LUADIR)/openbus/core/admin/messages.lua \
	$(LUADIR)/openbus/core/admin/print.lua \
	$(LUADIR)/openbus/core/admin/script.lua \
	$(LUADIR)/openbus/core/services/Access.lua \
	$(LUADIR)/openbus/core/services/AccessControl.lua \
	$(LUADIR)/openbus/core/services/LoginDB.lua \
	$(LUADIR)/openbus/core/services/main.lua \
	$(LUADIR)/openbus/core/services/messages.lua \
	$(LUADIR)/openbus/core/services/OfferIndex.lua \
	$(LUADIR)/openbus/core/services/OfferRegistry.lua \
	$(LUADIR)/openbus/core/services/passwordvalidator/LDAP.lua

include ${OIL_HOME}/openbus/base.mak

LIBS= \
	dl crypto ldap \
	lua5.1 luuid lce lfs lpw lualdap luavararg luastruct luasocket \
	loop luatuple luacoroutine luacothread luainspector luaidl oil luascs luaopenbus

DEFINES= \
	OPENBUS_MAIN=\"openbus.core.admin.main\" \
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

$(PRELOAD_DIR)/coreadmin.c $(PRELOAD_DIR)/coreadmin.h: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h coreadmin.h \
	                           -o coreadmin.c \
	                           $(LUASRC)

coreadminlibs.c: $(PRELOAD_DIR)/coreadmin.h

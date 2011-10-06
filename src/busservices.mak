PROJNAME= OpenBus
APPNAME= busservices

USE_LUA51= YES

OPENBUSIDL= ${OPENBUS_HOME}/idlpath/v1_05
OPENBUSINC= ${OPENBUS_HOME}/incpath
OPENBUSLIB= ${OPENBUS_HOME}/libpath/$(TEC_UNAME)

SRC= \
	launcher.c \
	coreservlibs.c \
	coreservices.c

LUADIR= ../lua
LUAPCK= $(addprefix $(LUADIR)/, \
	openbus/core/legacy/AccessControlService.lua \
	openbus/core/legacy/idl.lua \
	openbus/core/legacy/parsed.lua \
	openbus/core/legacy/RegistryService.lua \
	openbus/core/services/Access.lua \
	openbus/core/services/AccessControl.lua \
	openbus/core/services/LoginDB.lua \
	openbus/core/services/main.lua \
	openbus/core/services/messages.lua \
	openbus/core/services/OfferIndex.lua \
	openbus/core/services/OfferRegistry.lua \
	openbus/core/services/passwordvalidator/LDAP.lua )

IDL= \
	$(OPENBUSIDL)/access_control_service.idl \
	$(OPENBUSIDL)/registry_service.idl \
	$(OPENBUSIDL)/fault_tolerance.idl

LIBS= \
	dl crypto ldap \
	luuid lce lpw lfs lualdap luavararg luastruct luasocket \
	loop looplib cothread luaidl oil scs openbus

DEFINES= \
	OPENBUS_MAIN=\"openbus.core.services.main\" \
	OPENBUS_PROGNAME=\"$(APPNAME)\"

INCLUDES+= . $(SRCLUADIR) \
	$(OPENBUSINC)/luuid \
	$(OPENBUSINC)/lce \
	$(OPENBUSINC)/lpw \
	$(OPENBUSINC)/luafilesystem \
	$(OPENBUSINC)/lualdap-1.0.1 \
	$(OPENBUSINC)/luavararg-1.1 \
	$(OPENBUSINC)/luastruct-1.1 \
	$(OPENBUSINC)/luasocket-2.0.2 \
	$(OPENBUSINC)/loop-3.0 \
	$(OPENBUSINC)/oil-0.6 \
	$(OPENBUSINC)/scs-1.2.3 \
	$(OPENBUSINC)/luaopenbus-2.0
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

$(LUADIR)/openbus/core/legacy/parsed.lua: $(IDL)
	$(LUABIN) ${OIL_HOME}/lua/idl2lua.lua -I $(OPENBUSIDL) -o $(SRCLUADIR)/$@ $^

coreservices.c coreservices.h: ${LOOP_HOME}/lua/preloader.lua $(LUAPCK)
	$(LUABIN) $< -l "$(LUADIR)/?.lua" -h coreservices.h -o coreservices.c $(filter-out $<,$^)

coreservlibs.c: coreservices.h

debug:
	echo "$(OPENBUSLIB)"
PROJNAME= busservices
APPNAME= $(PROJNAME)

SCSIDL= ${SCS_IDL1_2_HOME}/src
OPENBUSIDL= ${OPENBUS_IDL2_0_HOME}/src

SRC= \
  launcher.c \
  coreservlibs.c \
  $(PRELOAD_DIR)/coreservices.c

IDLDIR= ../idl
IDLSRC= \
  $(IDLDIR)/access_management.idl \
  $(IDLDIR)/offer_authorization.idl

DEPENDENTIDLSRC= \
  $(SCSIDL)/scs.idl \
  $(OPENBUSIDL)/core.idl \
  $(OPENBUSIDL)/credential.idl \
  $(OPENBUSIDL)/access_control.idl \
  $(OPENBUSIDL)/offer_registry.idl

LUADIR= ../lua
LUASRC= \
  $(LUADIR)/openbus/core/admin/idl.lua \
  $(LUADIR)/openbus/core/admin/parsed.lua \
  $(LUADIR)/openbus/core/legacy/AccessControlService.lua \
  $(LUADIR)/openbus/core/legacy/RegistryService.lua \
  $(LUADIR)/openbus/core/services/Access.lua \
  $(LUADIR)/openbus/core/services/AccessControl.lua \
  $(LUADIR)/openbus/core/services/LoginDB.lua \
  $(LUADIR)/openbus/core/services/main.lua \
  $(LUADIR)/openbus/core/services/messages.lua \
  $(LUADIR)/openbus/core/services/PropertyIndex.lua \
  $(LUADIR)/openbus/core/services/OfferRegistry.lua \
  $(LUADIR)/openbus/core/services/passwordvalidator/LDAP.lua

include ${OIL_HOME}/openbus/base.mak

LIBS:= lce luuid lfs luavararg luastruct  luasocket loop luatuple \
  luacoroutine luacothread luainspector luaidl oil luascs luaopenbus

DEFINES= \
  TECMAKE_APPNAME=\"$(APPNAME)\"

INCLUDES+= . $(SRCLUADIR) \
  $(LCE_HOME)/include \
  $(LUUID_HOME)/include \
  $(LUAFILESYSTEM_HOME)/include \
  $(LUASOCKET_HOME)/include \
  $(LUASTRUCT_HOME)/src \
  $(LUAVARARG_HOME)/src \
  $(LUAINSPECTOR_HOME)/obj/$(TEC_UNAME) \
  $(LUATUPLE_HOME)/obj/$(TEC_UNAME) \
  $(LUACOROUTINE_HOME)/obj/$(TEC_UNAME) \
  $(LUACOTHREAD_HOME)/obj/$(TEC_UNAME) \
  $(LOOP_HOME)/obj/$(TEC_UNAME) \
  $(LUAIDL_HOME)/obj/$(TEC_UNAME) \
  $(OIL_HOME)/obj/$(TEC_UNAME) \
  $(SCS_LUA_HOME)/obj/$(TEC_UNAME) \
  $(OPENBUS_LUA_HOME)/obj/$(TEC_UNAME)
LDIR+= \
  $(LCE_HOME)/lib/$(TEC_UNAME) \
  $(LUUID_HOME)/lib/$(TEC_UNAME) \
  $(LUAFILESYSTEM_HOME)/lib/$(TEC_UNAME) \
  $(LUASOCKET_HOME)/lib/$(TEC_UNAME) \
  $(LUASTRUCT_HOME)/lib/$(TEC_UNAME) \
  $(LUAVARARG_HOME)/lib/$(TEC_UNAME) \
  $(LUAINSPECTOR_HOME)/lib/$(TEC_UNAME) \
  $(LUATUPLE_HOME)/lib/$(TEC_UNAME) \
  $(LUACOROUTINE_HOME)/lib/$(TEC_UNAME) \
  $(LUACOTHREAD_HOME)/lib/$(TEC_UNAME) \
  $(LUAIDL_HOME)/lib/$(TEC_UNAME) \
  $(LOOP_HOME)/lib/$(TEC_UNAME) \
  $(OIL_HOME)/lib/$(TEC_UNAME) \
  $(SCS_LUA_HOME)/lib/$(TEC_UNAME) \
  $(OPENBUS_LUA_HOME)/lib/$(TEC_UNAME)

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
endif

ifneq "$(TEC_SYSNAME)" "Win32"
  INCLUDES+= $(LUALDAP_HOME)/include
  LDIR+= $(LUALDAP_HOME)/lib/$(TEC_UNAME)
  LIBS+= lualdap
endif

ifdef USE_STATIC
  SLIB:= $(foreach libname, $(LIBS) uuid ldap lber ssl crypto, ${OPENBUS_HOME}/lib/lib$(libname).a)
  ifeq "$(TEC_SYSNAME)" "SunOS"
    LIBS:= rt nsl socket resolv
  else
    LIBS:= 
  endif
else
  ifneq "$(TEC_SYSNAME)" "Win32"
    ifneq "$(TEC_SYSNAME)" "Darwin"
      LIBS+= uuid
    endif
  endif
endif

ifeq "$(TEC_SYSNAME)" "Win32"
  APPTYPE= console
else
  LIBS+= dl
endif

$(LUADIR)/openbus/core/admin/parsed.lua: $(IDL2LUA) $(IDLSRC) $(DEPENDENTIDLSRC)
	$(OILBIN) $(IDL2LUA) -I $(SCSIDL) -I $(OPENBUSIDL) -o $@ $(IDLSRC)

$(PRELOAD_DIR)/coreservices.c $(PRELOAD_DIR)/coreservices.h: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h coreservices.h \
	                           -o coreservices.c \
	                           $(LUASRC)

coreservlibs.c: $(PRELOAD_DIR)/coreservices.h

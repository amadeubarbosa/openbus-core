PROJNAME= busservices
APPNAME= $(PROJNAME)
CODEREV?= $(shell git rev-parse --short HEAD)

OPENBUSSCSIDL= ${SCS_IDL1_2_HOME}/src
OPENBUSNEWIDL= ${OPENBUS_IDL2_1_HOME}/src

OBJROOT = obj/$(PROJNAME)

SRC= \
  launcher.c \
  coreservlibs.c \
  $(PRELOAD_DIR)/coreservices.c

IDLDIR= ../idl
IDLSRC= \
  $(IDLDIR)/access_management.idl \
  $(IDLDIR)/offer_authorization.idl \
  $(IDLDIR)/configuration.idl

DEPENDENTIDLSRC= \
  $(OPENBUSSCSIDL)/scs.idl \
  $(OPENBUSNEWIDL)/openbus_core-2.1.idl \
  $(OPENBUSNEWIDL)/openbus_creden-2.1.idl \
  $(OPENBUSNEWIDL)/openbus_access-2.1.idl \
  $(OPENBUSNEWIDL)/openbus_offers-2.1.idl

LUADIR= ../lua
LUASRC= \
  $(LUADIR)/openbus/core/admin/idl.lua \
  $(LUADIR)/openbus/core/admin/parsed.lua \
  $(LUADIR)/openbus/core/legacy/ServiceWrappers.lua \
  $(LUADIR)/openbus/core/services/Access.lua \
  $(LUADIR)/openbus/core/services/AccessControl.lua \
  $(LUADIR)/openbus/core/services/AuditInterceptor.lua \
  $(LUADIR)/openbus/core/services/LoginDB.lua \
  $(LUADIR)/openbus/core/services/main.lua \
  $(LUADIR)/openbus/core/services/messages.lua \
  $(LUADIR)/openbus/core/services/PasswordAttempts.lua \
  $(LUADIR)/openbus/core/services/PropertyIndex.lua \
  $(LUADIR)/openbus/core/services/OfferRegistry.lua \
  $(LUADIR)/openbus/core/services/util.lua \
  $(LUADIR)/openbus/core/services/passwordvalidator/LDAP.lua

include ${OIL_HOME}/openbus/base.mak

DEFINES= \
  OPENBUS_PROGNAME=\"$(APPNAME)\" \
  OPENBUS_CODEREV=\"$(CODEREV)\"

LIBS:= \
  luaopenbusaudit \
  luaopenbus \
  luastruct \
  luasocket \
  luatuple \
  loop \
  luacothread \
  luaidl \
  oil \
  luavararg \
  lfs \
  luuid \
  lce \
  luasec \
  luascs \
  lsqlite3 \
  sqlite3

INCLUDES+= . \
  $(SRCLUADIR) \
  $(LUASTRUCT_HOME)/src \
  $(LUASOCKET_HOME)/include \
  $(LUATUPLE_HOME)/obj/$(TEC_UNAME) \
  $(LOOP_HOME)/obj/$(TEC_UNAME) \
  $(LUACOTHREAD_HOME)/obj/$(TEC_UNAME) \
  $(LUAIDL_HOME)/obj/$(TEC_UNAME) \
  $(OIL_HOME)/obj/$(TEC_UNAME) \
  $(LUAVARARG_HOME)/src \
  $(LUAFILESYSTEM_HOME)/include \
  $(LUUID_HOME)/include \
  $(LCE_HOME)/include \
  $(LUASEC_HOME)/include \
  $(SCS_LUA_HOME)/obj/$(TEC_UNAME) \
  $(OPENBUS_LUA_HOME)/obj/$(TEC_UNAME) \
  $(OPENBUS_LUA_HOME)/src \
  $(OPENBUS_AUDIT_AGENT_HOME)/obj/$(TEC_UNAME) \
  $(SQLITE_HOME) \
  $(LSQLITE3_HOME)
LDIR+= \
  $(LUASTRUCT_HOME)/lib/$(TEC_UNAME) \
  $(LUASOCKET_HOME)/lib/$(TEC_UNAME) \
  $(LUATUPLE_HOME)/lib/$(TEC_UNAME) \
  $(LOOP_HOME)/lib/$(TEC_UNAME) \
  $(LUACOTHREAD_HOME)/lib/$(TEC_UNAME) \
  $(LUAIDL_HOME)/lib/$(TEC_UNAME) \
  $(OIL_HOME)/lib/$(TEC_UNAME) \
  $(LUAVARARG_HOME)/lib/$(TEC_UNAME) \
  $(LUAFILESYSTEM_HOME)/lib/$(TEC_UNAME) \
  $(LUUID_HOME)/lib/$(TEC_UNAME) \
  $(LCE_HOME)/lib/$(TEC_UNAME) \
  $(LUASEC_HOME)/lib/$(TEC_UNAME) \
  $(SCS_LUA_HOME)/lib/$(TEC_UNAME) \
  $(OPENBUS_LUA_HOME)/lib/$(TEC_UNAME) \
  $(OPENBUS_AUDIT_AGENT_HOME)/lib/$(TEC_UNAME) \
  $(SQLITE_HOME)/.libs \
  $(LSQLITE3_HOME)/bbuild/install

ifdef USE_LUA51
  INCLUDES+= $(LUACOMPAT52_HOME)/c-api $(LUACOMPAT52_HOME)/obj/$(TEC_UNAME)
  LDIR+= $(LUACOMPAT52_HOME)/lib/$(TEC_UNAME)
  LIBS+= luacompat52 luabit32 luacompat52c
endif

ifeq "$(TEC_SYSNAME)" "Linux"
  LFLAGS = -Wl,-E -lpthread
endif
ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CFLAGS= -g -KPIC -mt -D_REENTRANT
  ifeq ($(TEC_WORDSIZE), TEC_64)
    CFLAGS+= -m64
  endif
  LFLAGS= $(CFLAGS) -xildoff
endif

ifeq ($(findstring $(TEC_SYSNAME), Win32 Win64), )
  INCLUDES+= $(LUALDAP_HOME)/include
  LDIR+= $(LUALDAP_HOME)/lib/$(TEC_UNAME)
  LIBS+= lualdap
endif

ifeq ($(findstring $(TEC_SYSNAME), Win32 Win64), )
  ifdef USE_STATIC
    SLIB:= $(foreach libname, $(LIBS) uuid ldap lber ssl crypto, ${OPENBUS_HOME}/lib/lib$(libname).a)
    ifeq "$(TEC_SYSNAME)" "SunOS"
      LIBS:= rt nsl socket resolv
    else
      LIBS:= 
    endif
  else
    ifneq "$(TEC_SYSNAME)" "Darwin"
      LIBS+= uuid
    endif
  endif
endif

ifneq ($(findstring $(TEC_SYSNAME), Win32 Win64), )
  APPTYPE= console
  LIBS+= wsock32 rpcrt4
  ifneq ($(findstring dll, $(TEC_UNAME)), ) # USE_DLL
    ifdef DBG
      LIBS+= libeay32MDd ssleay32MDd
    else
      LIBS+= libeay32MD ssleay32MD
    endif
    LDIR+= $(OPENSSL_HOME)/lib/VC
  else
    ifdef DBG
      LIBS+= libeay32MTd ssleay32MTd
    else
      LIBS+= libeay32MT ssleay32MT
    endif
    LDIR+= $(OPENSSL_HOME)/lib/VC/static
  endif
else
  LIBS+= dl
endif

$(LUADIR)/openbus/core/admin/parsed.lua: $(IDL2LUA) $(IDLSRC) $(DEPENDENTIDLSRC)
	$(OILBIN) $(IDL2LUA) -I $(OPENBUSSCSIDL) -I $(OPENBUSNEWIDL) -o $@ $(IDLSRC)

$(PRELOAD_DIR)/coreservices.c $(PRELOAD_DIR)/coreservices.h: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h coreservices.h \
	                           -o coreservices.c \
	                           $(LUASRC)

launcher.c: $(OPENBUS_LUA_HOME)/src/launcher.c
	cp $< $@

coreservlibs.c: $(PRELOAD_DIR)/coreservices.h

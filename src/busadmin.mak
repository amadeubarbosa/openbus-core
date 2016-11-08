PROJNAME= busadmin
APPNAME= $(PROJNAME)
CODEREV?= r$(shell git rev-parse --short HEAD)

SCSIDL= ${SCS_IDL1_2_HOME}/src
OPENBUSIDL= ${OPENBUS_IDL2_0_HOME}/src

SRC= \
  launcher.c \
  adminlibs.c \
  $(PRELOAD_DIR)/coreadmin.c

IDLDIR= ../idl
IDLSRC= \
  $(IDLDIR)/access_management.idl \
  $(IDLDIR)/offer_authorization.idl \
  $(IDLDIR)/configuration.idl

DEPENDENTIDLSRC= \
  $(SCSIDL)/scs.idl \
  $(OPENBUSIDL)/core.idl \
  $(OPENBUSIDL)/credential.idl \
  $(OPENBUSIDL)/access_control.idl \
  $(OPENBUSIDL)/offer_registry.idl

LUADIR= ../lua
LUASRC= \
  $(LUADIR)/openbus/core/admin/idl.lua \
  $(LUADIR)/openbus/core/admin/main.lua \
  $(LUADIR)/openbus/core/admin/messages.lua \
  $(LUADIR)/openbus/core/admin/parsed.lua \
  $(LUADIR)/openbus/core/admin/print.lua \
  $(LUADIR)/openbus/core/admin/script.lua \

include ${OIL_HOME}/openbus/base.mak

LIBS:= \
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
  luascs \
  luaopenbus \
  lsqlite3 \
  sqlite3

DEFINES= \
  OPENBUS_PROGNAME=\"$(APPNAME)\" \
  OPENBUS_CODEREV=\"$(CODEREV)\"

INCLUDES+= . $(SRCLUADIR) \
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
  $(SCS_LUA_HOME)/obj/$(TEC_UNAME) \
  $(OPENBUS_LUA_HOME)/obj/$(TEC_UNAME) \
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
  $(SCS_LUA_HOME)/lib/$(TEC_UNAME) \
  $(OPENBUS_LUA_HOME)/lib/$(TEC_UNAME) \
  $(SQLITE_HOME)/.libs \
  $(LSQLITE3_HOME)/dist

ifdef USE_LUA51
  INCLUDES+= $(LUACOMPAT52_HOME)/c-api $(LUACOMPAT52_HOME)/obj/$(TEC_UNAME)
  LDIR+= $(LUACOMPAT52_HOME)/lib/$(TEC_UNAME)
  LIBS+= luacompat52 luabit32 luacompat52c
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
endif

ifdef USE_STATIC
  SLIB:= $(foreach libname, $(LIBS) uuid crypto, ${OPENBUS_HOME}/lib/lib$(libname).a)
  ifeq "$(TEC_SYSNAME)" "SunOS"
    LIBS:= rt nsl socket resolv
  else
    LIBS:= 
  endif
else
  ifeq ($(findstring $(TEC_SYSNAME), Win32 Win64), )
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
	$(OILBIN) $(IDL2LUA) -I $(SCSIDL) -I $(OPENBUSIDL) -o $@ $(IDLSRC)

$(PRELOAD_DIR)/coreadmin.c $(PRELOAD_DIR)/coreadmin.h: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -l "$(LUADIR)/?.lua" \
                             -d $(PRELOAD_DIR) \
                             -h coreadmin.h \
                             -o coreadmin.c \
                             $(LUASRC)

adminlibs.c: $(PRELOAD_DIR)/coreadmin.h

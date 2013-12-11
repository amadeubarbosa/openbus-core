PROJNAME= busadmin
APPNAME= $(PROJNAME)

SCSIDL= ${SCS_IDL1_2_HOME}/src
OPENBUSIDL= ${OPENBUS_IDL2_0_HOME}/src

SRC= \
  launcher.c \
  adminlibs.c \
  $(PRELOAD_DIR)/coreadmin.c

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
  $(LUADIR)/openbus/core/admin/main.lua \
  $(LUADIR)/openbus/core/admin/messages.lua \
  $(LUADIR)/openbus/core/admin/parsed.lua \
  $(LUADIR)/openbus/core/admin/print.lua \
  $(LUADIR)/openbus/core/admin/script.lua \

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
  LIBS+= wsock32 libeay32MD ssleay32MD
  ifeq "$(TEC_WORDSIZE)" "TEC_32"
    LDIR+= ../../OpenSSL-Win32/lib/VC
  else
    LDIR+= ../../OpenSSL-Win64/lib/VC
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

PROJNAME= busadmin
APPNAME= $(PROJNAME)

OPENBUSINC= ${OPENBUS_HOME}/include
OPENBUSLIB= ${OPENBUS_HOME}/lib
OPENBUSIDL= ${OPENBUS_HOME}/idl/v2_0

SRC= \
  launcher.c \
  adminlibs.c \
  $(PRELOAD_DIR)/coreadmin.c

IDLDIR= ../idl
IDLSRC= \
  $(IDLDIR)/access_management.idl \
  $(IDLDIR)/offer_authorization.idl

LUADIR= ../lua
LUASRC= \
  $(LUADIR)/openbus/core/admin/idl.lua \
  $(LUADIR)/openbus/core/admin/main.lua \
  $(LUADIR)/openbus/core/admin/messages.lua \
  $(LUADIR)/openbus/core/admin/parsed.lua \
  $(LUADIR)/openbus/core/admin/print.lua \
  $(LUADIR)/openbus/core/admin/script.lua \

include ${LOOP_HOME}/openbus/base.mak

LIBS:= lce luuid lfs luavararg luastruct  luasocket loop luatuple \
  luacoroutine luacothread luainspector luaidl oil luascs luaopenbus lua5.1

DEFINES= \
  TECMAKE_APPNAME=\"$(APPNAME)\"

INCLUDES+= . $(SRCLUADIR) \
  $(OPENBUSINC)/luuid \
  $(OPENBUSINC)/lce \
  $(OPENBUSINC)/luafilesystem \
  $(OPENBUSINC)/luavararg \
  $(OPENBUSINC)/luastruct \
  $(OPENBUSINC)/luasocket2 \
  $(OPENBUSINC)/loop \
  $(OPENBUSINC)/oil \
  $(OPENBUSINC)/scs/lua \
  $(OPENBUSINC)/openbus/lua
LDIR+= $(OPENBUSLIB)

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
  SLIB:= $(foreach libname, $(LIBS) uuid crypto, $(OPENBUSLIB)/lib$(libname).a)
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

LIBS+= dl

$(LUADIR)/openbus/core/admin/parsed.lua: $(IDL2LUA) $(IDLSRC)
	$(OILBIN) $(IDL2LUA) -I $(OPENBUSIDL) -o $@ $(IDLSRC)

$(PRELOAD_DIR)/coreadmin.c $(PRELOAD_DIR)/coreadmin.h: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -l "$(LUADIR)/?.lua" \
                             -d $(PRELOAD_DIR) \
                             -h coreadmin.h \
                             -o coreadmin.c \
                             $(LUASRC)

adminlibs.c: $(PRELOAD_DIR)/coreadmin.h

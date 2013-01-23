PROJNAME= busservices
APPNAME= $(PROJNAME)

OPENBUSINC= ${OPENBUS_HOME}/include
OPENBUSLIB= ${OPENBUS_HOME}/lib

SRC= \
  launcher.c \
  coreservlibs.c \
  $(PRELOAD_DIR)/coreservices.c

LUADIR= ../lua
LUASRC= \
  $(LUADIR)/openbus/core/legacy/AccessControlService.lua \
  $(LUADIR)/openbus/core/legacy/RegistryService.lua \
  $(LUADIR)/openbus/core/services/Access.lua \
  $(LUADIR)/openbus/core/services/AccessControl.lua \
  $(LUADIR)/openbus/core/services/LoginDB.lua \
  $(LUADIR)/openbus/core/services/main.lua \
  $(LUADIR)/openbus/core/services/messages.lua \
  $(LUADIR)/openbus/core/services/PropertyIndex.lua \
  $(LUADIR)/openbus/core/services/OfferRegistry.lua \
  $(LUADIR)/openbus/core/services/passwordvalidator/LDAP.lua \
  $(LUADIR)/openbus/util/database.lua

include ${OIL_HOME}/openbus/base.mak

LIBS:= lce luuid lfs lualdap luavararg luastruct  luasocket loop luatuple \
  luacoroutine luacothread luainspector luaidl oil luascs luaopenbus

DEFINES= \
  TECMAKE_APPNAME=\"$(APPNAME)\"

INCLUDES+= . $(SRCLUADIR) \
  $(OPENBUSINC)/luuid \
  $(OPENBUSINC)/lce \
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
  SLIB:= $(foreach libname, $(LIBS) uuid ldap lber ssl crypto, $(OPENBUSLIB)/lib$(libname).a)
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

$(PRELOAD_DIR)/coreservices.c $(PRELOAD_DIR)/coreservices.h: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -l "$(LUADIR)/?.lua" \
                             -d $(PRELOAD_DIR) \
                             -h coreservices.h \
                             -o coreservices.c \
                             $(LUASRC)

coreservlibs.c: $(PRELOAD_DIR)/coreservices.h

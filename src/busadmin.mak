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
	$(LUADIR)/openbus/core/admin/main.lua \
	$(LUADIR)/openbus/core/admin/messages.lua \
	$(LUADIR)/openbus/core/admin/print.lua \
	$(LUADIR)/openbus/core/admin/script.lua \

include ${LOOP_HOME}/openbus/base.mak

LIBS= \
	dl crypto ldap \
	lua5.1 luuid lce lfs lpw luavararg luastruct luasocket \
	loop luatuple luacoroutine luacothread luainspector luaidl oil luascs luaopenbus

DEFINES= \
	TECMAKE_APPNAME=\"$(APPNAME)\"

INCLUDES+= . $(SRCLUADIR) \
	$(OPENBUSINC)/luuid \
	$(OPENBUSINC)/lce \
	$(OPENBUSINC)/lpw \
	$(OPENBUSINC)/luafilesystem \
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

adminlibs.c: $(PRELOAD_DIR)/coreadmin.h

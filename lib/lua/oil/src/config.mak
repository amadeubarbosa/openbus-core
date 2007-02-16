#file "config.mak"

PROJNAME = oil
LIBNAME = oilall

LUABIN= $(LUA51)/bin/$(TEC_UNAME)/lua5.1

TARGETROOT= ${OPENBUS_HOME}/libpath

PRECMP_DIR=	$(OBJDIR)

PRECMP_LUA=	../lua/precompiler.lua
PRELDR_LUA=	../lua/preloader.lua

# Flags for pre-compilation of Lua scripts
PC_FLAGS= -p OIL_API -l ../lua -d $(PRECMP_DIR)
# Flags for generation of pre-loader of Lua scripts
PLD_FLAGS= -p OIL_API

PRECMP_INC= $(PRECMP_DIR)/scheduler.h $(PRECMP_DIR)/luaidl.h $(PRECMP_DIR)/loop.h $(PRECMP_DIR)/oil.h
PRECMP_SRC= $(PRECMP_DIR)/scheduler.c $(PRECMP_DIR)/luaidl.c $(PRECMP_DIR)/loop.c $(PRECMP_DIR)/oil.c

INC= oilbit.h oilall.h $(PRECMP_INC)
SRC= oilbit.c oilall.c $(PRECMP_SRC)

EXPINC= oilall.h
EXTRADEPS= $(PRECMP_DIR)

LOOP_PCK= loop/base.lua \
          loop/cached.lua \
          loop/init.lua \
          loop/multiple.lua \
          loop/scoped.lua \
          loop/simple.lua \
          loop/utils.lua \
          loop/collection/MapWithKeyArray.lua \
          loop/collection/ObjectCache.lua \
          loop/collection/OrderedSet.lua \
          loop/collection/PriorityQueue.lua \
          loop/collection/UnorderedArray.lua \
          loop/collection/UnorderedArraySet.lua \
          loop/compiler/Conditional.lua \
          loop/debug/verbose.lua \
          loop/debug/Viewer.lua \
          loop/extras/Exception.lua \
          loop/extras/Wrapper.lua
LUAIDL_PCK= luaidl/init.lua \
            luaidl/lex.lua \
            luaidl/pre.lua \
            luaidl/sin.lua
OIL_PCK= oil/assert.lua \
         oil/cdr.lua \
         oil/Exception.lua \
         oil/giop.lua \
         oil/idl/init.lua \
         oil/idl/compiler.lua \
         oil/iiop.lua \
         oil/init.lua \
         oil/invoke.lua \
         oil/ior.lua \
         oil/manager.lua \
         oil/oo.lua \
         oil/orb.lua \
         oil/proxy.lua \
         oil/socket.lua \
         oil/tcode.lua \
         oil/verbose.lua \
         oil/ir/idl.lua \
         oil/ir/init.lua
SCHEDULER_PCK= scheduler/init.lua

$(PRECMP_DIR)/loop.c $(PRECMP_DIR)/loop.h: $(PRECMP_LUA)
	$(LUABIN) $(PRECMP_LUA) $(PC_FLAGS) -f loop $(LOOP_PCK)
$(PRECMP_DIR)/luaidl.c $(PRECMP_DIR)/luaidl.h: $(PRECMP_LUA)
	$(LUABIN) $(PRECMP_LUA) $(PC_FLAGS) -f luaidl $(LUAIDL_PCK)
$(PRECMP_DIR)/oil.c $(PRECMP_DIR)/oil.h: $(PRECMP_LUA)
	$(LUABIN) $(PRECMP_LUA) $(PC_FLAGS) -f oil $(OIL_PCK)
$(PRECMP_DIR)/scheduler.c $(PRECMP_DIR)/scheduler.h: $(PRECMP_LUA)
	$(LUABIN) $(PRECMP_LUA) $(PC_FLAGS) -f scheduler $(SCHEDULER_PCK)

oilall.c oilall.h: $(PRELDR_LUA) oilbit.h $(PRECMP_INC)
	$(LUABIN) $(PRELDR_LUA) $(PLD_FLAGS) -f oilall oilbit.h $(PRECMP_INC)

clean-precomp:
	@(rm -f $(PRECMP_INC) $(PRECMP_SRC) oilall.h oilall.c)

USE_LUA51=yes

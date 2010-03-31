PROJNAME= tools
APPNAME= ${PROJNAME}

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
LUASRC_DIR= ../lua

OPENBUSLIB= ${OPENBUS_HOME}/libpath/${TEC_UNAME}

PRECMP_DIR= ../obj/${TEC_UNAME}
PRECMP_LUA= ../lua/precompiler.lua
PRECMP_FLAGS= -p TOOLS_API -o tools -l "$(LUASRC_DIR)/?.lua" -d $(PRECMP_DIR) -n

PRELOAD_LUA= ../lua/preloader.lua
PRELOAD_FLAGS= -p TOOLS_API -o toolsall -d ${PRECMP_DIR}

TOOLS_MODULES=$(addprefix tools., \
	config \
	build.tecmake \
	build.copy \
	build.autotools \
	build.maven \
	build.mavenimport \
	build.ant \
	build.command \
	fetch.http \
	fetch.svn \
	checklibdeps \
	platforms \
	split \
	util \
	compile \
	installer \
	makepack \
	hook \
	console )

TOOLS_LUA= \
$(addprefix $(LUASRC_DIR)/, \
  $(addsuffix .lua, \
    $(subst .,/, $(TOOLS_MODULES))))

${PRECMP_DIR}/tools.c: $(TOOLS_LUA) 
	$(LUABIN) $(LUA_FLAGS) $(PRECMP_LUA)   $(PRECMP_FLAGS) $(TOOLS_MODULES) 

${PRECMP_DIR}/toolsall.c: ${PRECMP_DIR}/tools.c
	$(LUABIN) $(LUA_FLAGS) $(PRELOAD_LUA)  $(PRELOAD_FLAGS) -i ${PRECMP_DIR} tools.h

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

SRC= ${PRECMP_DIR}/tools.c ${PRECMP_DIR}/toolsall.c lua.c

INCLUDES= . ${PRECMP_DIR}
LDIR += ${OPENBUSLIB}

USE_LUA51=YES
USE_STATIC=YES
NO_SCRIPTS=YES
USE_NODEPEND=YES

LIBS += dl

ifeq "$(TEC_SYSNAME)" "Linux"
  LFLAGS = -Wl,-E
endif
ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC= Yes
endif

.PHONY: clean-custom-obj
clean-custom-obj:
	rm -f ${PRECMP_DIR}/*.c
	rm -f ${PRECMP_DIR}/*.h

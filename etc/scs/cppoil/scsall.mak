PROJNAME= scsall
LIBNAME= ${PROJNAME}

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

PRECMP_DIR= ../obj/${TEC_UNAME}
PRECMP_LUA= ${LOOP_HOME}/precompiler.lua
PRECMP_FLAGS= -d ${PRECMP_DIR} -l ../../lua/\?.lua

PRELOAD_LUA= ${LOOP_HOME}/preloader.lua
PRELOAD_FLAGS= -d ${PRECMP_DIR} 

${PRECMP_DIR}/scs_core_base.c ${PRECMP_DIR}/scs_core_base.h:
	${LUABIN} ${PRECMP_LUA} -o scs_core_base ${PRECMP_FLAGS} -n scs.core.base

${PRECMP_DIR}/scs_core_utils.c ${PRECMP_DIR}/scs_core_utils.h:
	${LUABIN} ${PRECMP_LUA} -o scs_core_utils ${PRECMP_FLAGS} -n scs.core.utils

${PRECMP_DIR}/scsall.c ${PRECMP_DIR}/scsall.h: ${PRECMP_DIR}/scs_core_base.h ${PRECMP_DIR}/scs_core_utils.h
	${LUABIN} ${PRELOAD_LUA} -o scsall ${PRELOAD_FLAGS} ${PRECMP_DIR}/scs_core_base.h ${PRECMP_DIR}/scs_core_utils.h

INCLUDES= . ${PRECMP_DIR}
#LDIR= ${OPENBUSLIB}

LIBS= dl

SRC= ${PRECMP_DIR}/scs_core_base.c ${PRECMP_DIR}/scs_core_utils.c ${PRECMP_DIR}/scsall.c

USE_LUA51=YES
USE_STATIC=YES
USE_NODEPEND=YES


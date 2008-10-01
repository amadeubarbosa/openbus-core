PROJNAME= scsall
LIBNAME= ${PROJNAME}

OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

PRECMP_DIR= ../obj/${TEC_UNAME}

${PRECMP_DIR}/scs_core_IComponent.c ${PRECMP_DIR}/scs_core_IComponent.h:
	lua5.1 precompiler.lua -f scs_core_IComponent -d ${PRECMP_DIR} -l ../lua scs/core/IComponent.lua

${PRECMP_DIR}/scs_core_IMetaInterface.c ${PRECMP_DIR}/scs_core_IMetaInterface.h:
	lua5.1 precompiler.lua -f scs_core_IMetaInterface -d ${PRECMP_DIR} -l ../lua scs/core/IMetaInterface.lua

${PRECMP_DIR}/scsall.c ${PRECMP_DIR}/scsall.h: ${PRECMP_DIR}/scs_core_IMetaInterface.c ${PRECMP_DIR}/scs_core_IMetaInterface.h
	lua5.1 preloader.lua -o scsall -d ${PRECMP_DIR} ${PRECMP_DIR}/scs_core_IComponent.h ${PRECMP_DIR}/scs_core_IMetaInterface.h

INCLUDES= ../include ${PRECMP_DIR}
LDIR= ${OPENBUSLIB}

LIBS= dl

SRC= ${PRECMP_DIR}/scs_core_IComponent.c ${PRECMP_DIR}/scs_core_IMetaInterface.c ${PRECMP_DIR}/scsall.c

USE_LUA51=YES
USE_STATIC=YES


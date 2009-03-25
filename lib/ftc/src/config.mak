PROJNAME= ftc
LIBNAME= ${PROJNAME}

OPENBUSINC= ${OPENBUS_HOME}/incpath
OPENBUSLIB= ${OPENBUS_HOME}/libpath/${TEC_UNAME}

PRECMP_DIR= ../obj/${TEC_UNAME}

${PRECMP_DIR}/ftc_core.c ${PRECMP_DIR}/ftc_core.h:
	lua5.1 precompiler.lua -f ftc_core -d ${PRECMP_DIR} -l ../lua ftc.lua ftc/verbose.lua ftc/core.lua

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE
#DEFINES+=VERBOSE2

DEFINES+=_FILE_OFFSET_BITS=64 LUA_USELONGLONG
SRC= ${PRECMP_DIR}/ftc_core.c ftc.cpp

INCLUDES= ../include ${OPENBUSINC}/luasocket2 ${OPENBUSINC}/oil04 ${PRECMP_DIR}
LDIR += ${OPENBUSLIB}

LIBS= luasocket oilall stdc++

USE_LUA51=YES

distclean:
	rm -rf ${PRECMP_DIR}/ftc_core.*

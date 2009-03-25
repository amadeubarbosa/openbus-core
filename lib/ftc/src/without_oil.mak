PROJNAME= ftcwooil
LIBNAME= ${PROJNAME}

OPENBUSINC= ${OPENBUS_HOME}/incpath
OPENBUSLIB= ${OPENBUS_HOME}/libpath/${TEC_UNAME}

PRECMP_DIR= ../obj/${TEC_UNAME}

${PRECMP_DIR}/ftcwooil_core.c ${PRECMP_DIR}/ftcwooil_core.h:
	lua5.1 precompiler.lua -f ftcwooil_core -d ${PRECMP_DIR} -l ../lua ftcwooil.lua ftc/verbose.lua ftc/core.lua

DEFINES+= WITHOUT_OIL

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES+=VERBOSE
#DEFINES+=VERBOSE2

DEFINES+=_FILE_OFFSET_BITS=64 LUA_USELONGLONG
SRC= ${PRECMP_DIR}/ftcwooil_core.c ftc.cpp

INCLUDES= ../include ${OPENBUSINC}/luasocket2 ${PRECMP_DIR}
LDIR+= ${OPENBUSLIB}

LIBS= luasocket

USE_LUA51=YES

distclean:
	rm -rf ${PRECMP_DIR}/ftc_core.*

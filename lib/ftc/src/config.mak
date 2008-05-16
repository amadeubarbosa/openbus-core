PROJNAME= ftc
LIBNAME= ${PROJNAME}

OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

PRECMP_DIR= ../obj/${TEC_UNAME}

${PRECMP_DIR}/ftc_core.c ${PRECMP_DIR}/ftc_core.h:
	lua5.1 precompiler.lua -f ftc_core -d ../obj/${TEC_UNAME} -l ../lua ftc/init.lua ftc/verbose.lua

${PRECMP_DIR}/auxiliar.c ${PRECMP_DIR}/auxiliar.h:
	lua5.1 precompiler.lua -f auxiliar -d ../obj/${TEC_UNAME} -l ../lua auxiliar.lua

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE
#DEFINES+=VERBOSE2

SRC= ftc.cpp ${PRECMP_DIR}/ftc_core.c ${PRECMP_DIR}/auxiliar.c

INCLUDES= ../include
LDIR += ${OPENBUSLIB}

LIBS= luasocket oilall

USE_LUA51=YES


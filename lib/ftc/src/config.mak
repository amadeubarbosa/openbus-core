PROJNAME= ftc
LIBNAME= ${PROJNAME}

OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

SRC= auxiliar.c ftc.cpp

INCLUDES= ../include
LDIR += ${OPENBUSLIB}

USE_LUA51=YES

LIBS= luasocket

precompile:
	${LUA51}/bin/${TEC_UNAME}/lua5.1 precompiler.lua -f auxiliar -p auxiliar auxiliar.lua

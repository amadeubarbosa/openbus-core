PROJNAME= ftc
LIBNAME= ${PROJNAME}

INCLUDES= ../include
SRC= auxiliar.c ftc.cpp

LDIR= ${LUASOCKET2LIB}
LIBS= luasocket

USE_LUA51=YES

precompile:
	${LUA51}/bin/${TEC_UNAME}/lua5.1 precompiler.lua -f auxiliar -p auxiliar auxiliar.lua


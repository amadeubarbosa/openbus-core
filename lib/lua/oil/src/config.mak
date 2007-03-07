#file "config.mak"

PROJNAME = oil
LIBNAME = oilbit

LUABIN= ${LUA_HOME}/bin/$(TEC_UNAME)/${LUA}

TARGETROOT= ${OPENBUS_HOME}/libpath

OILBIT_INC=	oilbit.h
OILBIT_OBJ=	oilbit.o
OILBIT_LIB=	liboilbit.a
OILBIT_SOL=	liboilbit.0.3.so

INC= ${OILBIT_INC}
SRC= oilbit.c

USE_LUA51=yes

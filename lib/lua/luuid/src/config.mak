#file "config.mak"

PROJNAME = luuid
LIBNAME = ${PROJNAME}

TARGETROOT= ${OPENBUS_HOME}/libpath

SRC=  luuid.c
LIBS= uuid

USE_LUA51=YES
USE_STATIC=YES

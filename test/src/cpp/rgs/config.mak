EXTRA_CONFIG=../../../../src/cpp/config

PROJNAME= openbus
APPNAME= runner

OBJROOT= ../../../bin/cpp/rgs
TARGETROOT= ../../../bin/cpp/rgs

LDIR= ${LUA51LIB} ${TOLUA_LIB}

INCLUDES=../../../../include ${CXXTEST_INC} ${TOLUA_INC} ${LUA_INC}
LIBS= dl lua5.1 tolua

SLIB= ${OPENBUS_HOME}/lib/cpp/${TEC_UNAME}/libopenbus.a

SRC= runner.cpp hellobind.cpp

USE_STATIC=YES


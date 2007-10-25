EXTRA_CONFIG=../../../../src/cpp/config

PROJNAME= openbus
APPNAME= runner

OBJROOT= ../../../bin/cpp/ses
TARGETROOT= ../../../bin/cpp/ses

LDIR= ${LUA51LIB} ${TOLUA_LIB}

INCLUDES=../../../../include ${CXXTEST_INC} ${TOLUA_INC} ${LUA_INC}
LIBS= dl lua5.1 tolua

SLIB= ${OPENBUS_HOME}/lib/cpp/${TEC_UNAME}/libopenbus.a

SRC= runner.cpp

USE_STATIC=YES


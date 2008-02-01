EXTRA_CONFIG=../../../../src/cpp/oil/config

PROJNAME= openbus
APPNAME= runner

OBJROOT= ../../../bin/cpp/acs
TARGETROOT= ../../../bin/cpp/acs

LDIR= ${LUA51LIB} ${TOLUA_LIB}

INCLUDES= ../../../../include ${CXXTEST_INC} ${TOLUA_INC}
LIBS= dl lua5.1 tolua

SLIB= ${OPENBUS_HOME}/lib/cpp/${TEC_UNAME}/libopenbus.a

SRC= runner.cpp

USE_STATIC=YES


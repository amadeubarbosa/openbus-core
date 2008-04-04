EXTRA_CONFIG=${OPENBUS_HOME}/src/openbus/cpp/oil/config

PROJNAME= openbus
APPNAME= runner

OBJROOT= ../../../bin/cpp/rgs
TARGETROOT= ../../../bin/cpp/rgs

LDIR= ${LUA51LIB} ${TOLUA_LIB}

INCLUDES= ${OPENBUS_HOME}/include ${CXXTEST_INC} ${TOLUA_INC}
LIBS= dl tolua oilbit luasocket

SLIB= ${OPENBUS_HOME}/lib/cpp/${TEC_UNAME}/libopenbus.a

SRC= runner.cpp hellobind.cpp

USE_LUA51=YES
USE_STATIC=YES

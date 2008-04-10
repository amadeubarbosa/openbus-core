EXTRA_CONFIG=${OPENBUS_HOME}/src/openbus/cpp/oil/config

PROJNAME= openbus
APPNAME= runner

OBJROOT= ../../../bin/cpp/ses
TARGETROOT= ../../../bin/cpp/ses

INCLUDES= ${OPENBUS_HOME}/include ${CXXTEST_INC} ${TOLUA_INC}

LIBS= dl

SLIB= ${OPENBUS_HOME}/lib/cpp/${TEC_UNAME}/libopenbus.a \
      ${OIL04LIB}/liboilall.a \
      ${LUASOCKET2LIB}/libluasocket.a \
      ${TOLUA_LIB}/libtolua.a

SRC= runner.cpp

USE_LUA51=YES
USE_STATIC=YES

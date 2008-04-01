EXTRA_CONFIG=${OPENBUS_HOME}/src/openbus/cpp/oil/config

PROJNAME= openbus
APPNAME= runner

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= ../../../bin/cpp/ProjectService
TARGETROOT= ../../../bin/cpp/ProjectService

LDIR= ${LUA51LIB} ${TOLUA_LIB}

INCLUDES= ${OPENBUS_HOME}/include ${CXXTEST_INC} ${TOLUA_INC}
LIBS= dl tolua oilbit luasocket

SLIB= ${OPENBUS_HOME}/lib/cpp/${TEC_UNAME}/libopenbus.a

SRC= runner.cpp ${OPENBUS_HOME}/src/extras/services/ProjectService/IProjectService.cpp

USE_LUA51=YES
USE_STATIC=YES

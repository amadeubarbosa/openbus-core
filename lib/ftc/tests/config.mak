PROJNAME= ftctest
APPNAME= runner

DEFINES= _FILE_OFFSET_BITS=64

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

INCLUDES= ../include ${OPENBUSINC}/cxxtest
LDIR= ${OPENBUSLIB}

SRC= runner.cpp

LIBS= dl oilall luasocket ftc

USE_LUA51=YES
USE_STATIC=YES

cxxtest:
	cxxtestgen.pl --runner=StdioPrinter -o runner.cpp TestSuite.cpp


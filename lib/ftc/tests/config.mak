PROJNAME= ftctest
APPNAME= runner
CXXTESTGEN = ../../cxxtest/cxxtestgen.pl
DEFINES= _FILE_OFFSET_BITS=64

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

INCLUDES= ../include ${OPENBUSINC}/cxxtest
LDIR= ${OPENBUSLIB}

SRC= runner.cpp

CPPFLAGS= -g

LIBS= dl oilall luasocket ftc ssl crypto

USE_LUA51=YES

cxxtest:
	${CXXTESTGEN} --runner=StdioPrinter -o runner.cpp TestSuite.cpp


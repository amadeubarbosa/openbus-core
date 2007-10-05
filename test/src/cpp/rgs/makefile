#
# rgs/makefile
#

include ../../../../src/cpp/config

RM= rm -rf
LIBS=-llua5.1 -ldl -ltolua

gentests:
	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runner.cpp RGSTestSuite.h
	g++ -o ../../../bin/cpp/rgs/runner runner.cpp hellobind.cpp ../../../../lib/cpp/openbus.a \
		-I${CXXTEST_INC} -I ${LUA_INC} -I${TOLUA_INC} -I../../../../include \
		-L${LUA_LIB} -L${TOLUA_LIB} \
		${LIBS} \
		${VERBOSE} ${VERBOSE2}

clean:
	${RM} runner runner.cpp

#
# tests/rgs/makefile
#

include ../../config

RM= rm -rf
LIBS=-llua5.1 -ldl -ltolua

gentests:
	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runner.cpp RGSTestSuite.h
	g++ -o runner runner.cpp hellobind.cpp ../../src/openbus.a \
		-I${CXXTEST_INC} -I ${LUA_INC} -I${TOLUA_INC} \
		-L${LUA_LIB} -L${TOLUA_LIB} \
		${LIBS} \
		${VERBOSE} ${VERBOSE2}

run:
	runtests

clean:
	${RM} runner runner.cpp

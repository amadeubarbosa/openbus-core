#
# tests/ses/makefile
#

include ../../config

RM= rm -rf
LIBS=-llua5.1 -ldl -ltolua

gentests:
	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runner.cpp SESTestSuite.h
	g++ -o runner runner.cpp ../../src/openbus.a \
		-I${CXXTEST_INC} \
		-L${LUA_LIB} -L${TOLUA_LIB} \
		${LIBS} \
		${VERBOSE} ${VERBOSE2}

run:
	runtests

clean:
	${RM} runner runner.cpp

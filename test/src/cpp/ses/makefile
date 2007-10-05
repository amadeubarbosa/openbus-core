#
# ses/makefile
#

include ../../../../src/cpp/config

RM= rm -rf
LIBS=-llua5.1 -ldl -ltolua

gentests:
	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runner.cpp SESTestSuite.h
	g++ -o ../../../bin/cpp/ses/runner runner.cpp ../../../../lib/cpp/openbus.a \
		-I${CXXTEST_INC} -I../../../../include \
		-L${LUA_LIB} -L${TOLUA_LIB} \
		${LIBS} \
		${VERBOSE} ${VERBOSE2}

clean:
	${RM} ../../../bin/cpp/acs/runner runner.cpp

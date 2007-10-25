#
# acs/makefile
#

include ../../../../src/cpp/config

RM= rm -rf
LIBS=-llua5.1 -ldl -ltolua

gentests:
	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runner.cpp ACSTestSuite.cpp
	tecmake
#	g++ -o ../../../bin/cpp/acs/runner runner.cpp ../../../../lib/cpp/${TEC_UNAME}/libopenbus.a \
		-I${CXXTEST_INC} -I${TOLUA_INC} -I../../../../include \
		-L${LUA_LIB} -L${TOLUA_LIB} \
		${LIBS} \
		${VERBOSE} ${VERBOSE2}

clean:
	tecmake clean
	${RM} runner.cpp 

#
# ProjectService/makefile
#

include ${OPENBUS_HOME}/src/openbus/cpp/oil/config

RM= rm -rf

gentests:
	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runner.cpp TestSuite.cpp
	tecmake

clean:
	tecmake clean
	${RM} runner.cpp 

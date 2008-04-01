#
#	tests/makefile
#

include ../config

#Descomente a linha abaixo para que os dados recebidos
#durante a execução dos testes, sejam gravados no disco.
#GENRCVED=-DGENRCVED

gentests:
	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runner.cpp TestSuite.h
	g++ ${FLAGS} -o runner runner.cpp ../src/${FTCLIB_A} \
		-I${CXXTEST} -I${LUA_INC} \
		${LIBS_PATH} \
		${LIBS} ${VERBOSE} ${VERBOSE2}

# # 	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runnerWithLF.cpp TestWithLargeFilesSuite.h
# # 	g++ ${FLAGS} -o runnerWithLF runnerWithLF.cpp ../src/${FTCLIB_A} \
# # 		-I${CXXTEST} \
# 		${LIBS_PATH} \
# 		${LIBS} ${VERBOSE} ${VERBOSE2}

# # 	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runnerBig.cpp TestLargeFileSuite.h
# # 	g++ ${FLAGS} -o runnerBig runnerBig.cpp ../src/${FTCLIB_A} \
# # 		-I${CXXTEST} \
# 		${LIBS_PATH} \
# 		${LIBS} ${VERBOSE} ${VERBOSE2}

# # 	${CXXTEST}/cxxtestgen.pl --runner=StdioPrinter -o runnerCo.cpp TestCoSuite.h
# # 	g++ ${FLAGS} -o runnerCo runnerCo.cpp ../src/${FTCLIB_A} \
# # 		-I${CXXTEST} -I${LUA_INC} \
# 		${LIBS_PATH} \
# 		${LIBS} ${VERBOSE} ${VERBOSE2}

clean:
	rm -f *.o ref.ior runner runner.cpp runnerCo runnerCo.cpp
	cd overhead && ${MAKE} clean
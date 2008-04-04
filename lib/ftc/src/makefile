#
#	src/makefile
#

include ../config

LUA_INC=${HOME}/tecgraf/lib/lua5.1/include


all:
	gcc ${FLAGS} -c auxiliar.c -I${LUA_INC} ${VERBOSE} ${VERBOSE2}
	gcc ${FLAGS} -c luasocketext/cbuffer.c -I${LUA_INC} -I${LUASOCKET2_INC} ${VERBOSE} ${VERBOSE2}
	g++ ${FLAGS} -c ftc.cpp	-I${LUA_INC} ${VERBOSE} ${VERBOSE2}
	${AR} ${FTCLIB_A} ${OBJS}
	${RANLIB} ${FTCLIB_A}

precompile:
	${LUABIN} precompiler.lua -f auxiliar -p auxiliar auxiliar.lua

clean:
	${RM} ${OBJS} *.a

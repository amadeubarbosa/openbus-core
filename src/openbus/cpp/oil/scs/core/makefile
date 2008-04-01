#
# scs/core/makefile
#

include ../../config

RM= rm -rf

all:
	g++ ${FLAGS} -c IComponent.cpp \
	-I${LUA_INC} -I${TOLUA_INC} -I../../../../../include \
	${VERBOSE} ${VERBOSE2}

clean:
	${RM} *.o


#
# services/makefile
#

include ../config

RM= rm -rf

all:
	g++ ${FLAGS} -c \
	IAccessControlService.cpp \
	IRegistryService.cpp \
	ISessionService.cpp \
	-I${LUA_INC} -I../../../../include \
	${VERBOSE} ${VERBOSE2}

clean:
	${RM} *.o


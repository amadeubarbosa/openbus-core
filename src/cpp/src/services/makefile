#
# src/services/makefile
#

include ../../config

RM= rm -rf

all:
	g++ ${FLAGS} -c \
	IAccessControlService.cpp \
	IRegistryService.cpp \
	ISessionService.cpp \
	-I${LUA_INC} \
	${VERBOSE} ${VERBOSE2}

clean:
	${RM} *.o


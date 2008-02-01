#
# common/makefile
#

include ../config

RM= rm -rf

all:
	g++ ${FLAGS} -c \
		CredentialManager.cpp \
		ClientInterceptor.cpp	\
		-I${LUA_INC} -I../../../../include \
		${VERBOSE} ${VERBOSE2}

clean:
	${RM} *.o


#
# src/common/makefile
#

include ../../config

RM= rm -rf

all:
	g++ ${FLAGS} -c \
		CredentialManager.cpp \
		ClientInterceptor.cpp	\
		-I${LUA_INC}	\
		${VERBOSE} ${VERBOSE2}

clean:
	${RM} *.o


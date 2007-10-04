#
#	src/makefile
#

include ../config

AR= ar rcu
RANLIB= ranlib
RM= rm -rf
OBJS= openbus.o \
			auxiliar.o \
			common/ClientInterceptor.o \
			common/CredentialManager.o \
			scs/core/IComponent.o \
			services/IAccessControlService.o \
			services/IRegistryService.o \
			services/ISessionService.o

OPENBUSLIB_A= openbus.a

all:
	${MAKE} -C common
	${MAKE} -C services
	${MAKE} -C scs/core
	gcc ${FLAGS} -c auxiliar.c -I${LUA_INC}
	g++ ${FLAGS} -c openbus.cpp \
		-I${LUA_INC} \
		${VERBOSE} ${VERBOSE2}
	${AR} ${OPENBUSLIB_A} ${OBJS}
	${RANLIB} ${OPENBUSLIB_A}

precompile:
	${LUABIN} precompiler.lua -f auxiliar -p auxiliar openbus.lua

clean:
	${RM} ${OBJS} ${OPENBUSLIB_A}
	cd common && ${MAKE} clean
	cd services && ${MAKE} clean
	cd scs/core && ${MAKE} clean


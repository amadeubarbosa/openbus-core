#
# makefile
#

include config

AR= ar rcu
RANLIB= ranlib
RM= rm -rf
MKDIR= mkdir -p
OBJS= openbus.o \
			auxiliar.o \
			common/ClientInterceptor.o \
			common/CredentialManager.o \
			scs/core/IComponent.o \
			services/IAccessControlService.o \
			services/IRegistryService.o \
			services/ISessionService.o \
			services/SessionEventSinkbind.o \

OPENBUSLIB_A= openbus.a

all:
	${MAKE} -C common
	${MAKE} -C services
	${MAKE} -C scs/core
	gcc ${FLAGS} -c auxiliar.c -I${LUA_INC} -I../../include
	g++ ${FLAGS} -c openbus.cpp \
		-I${LUA_INC} -I../../include \
		${VERBOSE} ${VERBOSE2}
	${MKDIR} ../../lib
	${MKDIR} ../../lib/cpp
	${AR} ../../lib/cpp/${OPENBUSLIB_A} ${OBJS}
	${RANLIB} ../../lib/cpp/${OPENBUSLIB_A}

precompile:
	${LUABIN} precompiler.lua -f auxiliar -p auxiliar openbus.lua

# install:
# 	${MKDIR} -p ${INSTALL_LIB} ${INSTALL_INC}
# 	${CP} src/openbus.a ${INSTALL_LIB}
# 	${CP} src/openbus.h ${INSTALL_INC}
# 	${CP} lua/RemoteFileChannel ${INSTALL_LUA}

clean:
	${RM} ${OBJS} ../../lib/cpp
	cd common && ${MAKE} clean
	cd services && ${MAKE} clean
	cd scs/core && ${MAKE} clean



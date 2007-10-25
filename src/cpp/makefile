#
# makefile
#

include config

#Descomente a linha abaixo caso deseje ativar o VERBOSE
VERBOSE=-DVERBOSE
VERBOSE2=-DVERBOSE2

#Pre-Compile options
LUABIN=${LUA51}/bin/${TEC_UNAME}/lua5.1

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

OPENBUSLIB_A= libopenbus.a

all:
	${MAKE} -C common
	${MAKE} -C services
	${MAKE} -C scs/core
	gcc ${FLAGS} -c auxiliar.c -I${LUA_INC} -I../../include
	g++ ${FLAGS} -c openbus.cpp \
		-I${LUA_INC} -I../../include \
		${VERBOSE} ${VERBOSE2}
	${MKDIR} -p ../../lib/cpp
	${AR} ../../lib/cpp/${OPENBUSLIB_A} ${OBJS}
	${RANLIB} ../../lib/cpp/${OPENBUSLIB_A}

precompile:
	${LUABIN} precompiler.lua -f auxiliar -p auxiliar openbus.lua

clean:
	${RM} ${OBJS} ../../lib/cpp
	cd common && ${MAKE} clean
	cd services && ${MAKE} clean
	cd scs/core && ${MAKE} clean



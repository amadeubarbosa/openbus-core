#file "config.mak"

PROJNAME = oil
LIBNAME = oilbit

LUABIN= ${LUA_HOME}/bin/$(TEC_UNAME)/${LUA}

TARGETROOT= ${OPENBUS_HOME}/libpath

OILBIT_INC=	oilbit.h
OILBIT_OBJ=	oilbit.o
OILBIT_LIB=	liboilbit.a
OILBIT_SOL=	liboilbit.0.3.so

INC= ${OILBIT_INC}
SRC= oilbit.c

USE_LUA51=yes

lib:
	@(cd ${TARGETROOT}/${TEC_UNAME}; mkdir -p liboil; cd liboil; \
		ln -sf ../liboilbit.so bit.so)
	@mkdir -p ${TARGETROOT}/lua
	@(cd ../lua; \
		tar czvf oil.tar.gz `find -name '*.lua' -mindepth 2`; \
		tar xzvf oil.tar.gz -C ${TARGETROOT}/lua; \
		rm oil.tar.gz)

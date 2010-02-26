PROJNAME= openbusmico
LIBNAME= ${PROJNAME}

DEFINES=SCS_MICO
DEFINES+=OPENBUS_MICO

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
endif

MICO_BIN= ${MICODIR}/bin
MICO_INC= ${MICODIR}/include
MICO_LIB=${MICODIR}/lib

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OBJROOT= obj
TARGETROOT= lib

INCLUDES= . ${MICO_INC} ${OPENBUSINC}/scs ${OPENBUSINC}/openssl-0.9.9
LDIR= ${MICO_LIB} ${OPENBUSLIB} ${MICO_LIB}

LIBS= mico2.3.11 scsmico crypto dl

SRC= openbus/interceptors/ClientInterceptor.cpp \
     openbus/interceptors/ServerInterceptor.cpp \
     openbus/interceptors/ORBInitializerImpl.cpp \
     stubs/mico/access_control_service.cc \
     stubs/mico/registry_service.cc \
     stubs/mico/session_service.cc \
     stubs/mico/core.cc \
     stubs/mico/scs.cc \
     openbus.cpp \
     openbus/util/Helper.cpp \
     logger.cpp

genstubs:
	mkdir -p stubs/mico
	ln -fs ${OPENBUS_HOME}/idlpath/core.idl stubs/mico
	ln -fs ${OPENBUS_HOME}/idlpath/scs.idl stubs/mico
	ln -fs ${OPENBUS_HOME}/idlpath/access_control_service.idl stubs/mico
	ln -fs ${OPENBUS_HOME}/idlpath/registry_service.idl stubs/mico
	ln -fs ${OPENBUS_HOME}/idlpath/session_service.idl stubs/mico
	cd stubs/mico ; ${MICO_BIN}/idl --any --typecode access_control_service.idl 
	cd stubs/mico ; ${MICO_BIN}/idl registry_service.idl
	cd stubs/mico ; ${MICO_BIN}/idl session_service.idl
	cd stubs/mico ; ${MICO_BIN}/idl core.idl
	cd stubs/mico ; ${MICO_BIN}/idl scs.idl
	
sunos58: $(OBJS)
	rm -f lib/SunOS58/libopenbusmico.a
	CC -xar -instances=extern -o lib/SunOS58/libopenbusmico.a $(OBJS)
	rm -f lib/SunOS58/libopenbusmico.so
	CC -G -instances=extern -Kpic -o lib/SunOS58/libopenbusmico.so $(OBJS)


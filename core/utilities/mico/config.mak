PROJNAME= openbus_mico
LIBNAME= ${PROJNAME}

#Descomente a linha abaixo para ativar o suporte a multithread.
#DEFINES=MULTITHREAD

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES+=VERBOSE

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
endif

MICO_HOME=/usr/local
MICO_BIN= ${MICO_HOME}/bin
MICO_INC= ${MICO_HOME}/include
MICO_LDIR=${MICO_HOME}/lib

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OBJROOT= obj
TARGETROOT= lib

INCLUDES= . ${MICO_INC} ${OPENBUSINC}/scs/mico ${OPENBUSINC}/openssl-0.9.9
LDIR= ${MICO_LDIR} ${OPENBUSLIB} ${MICO_LDIR}

LIBS= mico2.3.11 dl crypto

SRC= openbus/interceptors/ClientInterceptor.cpp \
     openbus/interceptors/ServerInterceptor.cpp \
     openbus/interceptors/ORBInitializerImpl.cpp \
     openbus/util/Helper.cpp \
     stubs/access_control_service.cc \
     stubs/registry_service.cc \
     stubs/session_service.cc \
     stubs/core.cc \
     stubs/scs.cc \
     openbus.cpp \
     verbose.cpp

genstubs:
	mkdir -p stubs
	ln -fs ../../../../idlpath/core.idl stubs/
	ln -fs ../../../../idlpath/scs.idl stubs/
	ln -fs ../../../../idlpath/access_control_service.idl stubs/
	ln -fs ../../../../idlpath/registry_service.idl stubs/
	ln -fs ../../../../idlpath/session_service.idl stubs/
	cd stubs ; ${MICO_BIN}/idl --any --typecode access_control_service.idl 
	cd stubs ; ${MICO_BIN}/idl registry_service.idl
	cd stubs ; ${MICO_BIN}/idl session_service.idl
	cd stubs ; ${MICO_BIN}/idl core.idl
	cd stubs ; ${MICO_BIN}/idl scs.idl
	
sunos58: $(OBJS)
	rm -f lib/SunOS58/libopenbus_mico.a
	CC -xar -instances=extern -o lib/SunOS58/libopenbus_mico.a $(OBJS)
	rm -f lib/SunOS58/libopenbus_mico.so
	CC -G -instances=extern -Kpic -o lib/SunOS58/libopenbus_mico.so $(OBJS)


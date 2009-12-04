PROJNAME= openbusorbix
LIBNAME= ${PROJNAME}

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

ifeq "$(TEC_UNAME)" "SunOS58"
  USE_CC=Yes
endif

ORBIX_HOME= ${IT_PRODUCT_DIR}/asp/6.3
ORBIXINC= ${ORBIX_HOME}/include

ifeq ($(TEC_WORDSIZE), TEC_64)
  ORBIXLDIR=${ORBIX_HOME}/lib/lib64
else
  ORBIXLDIR=${ORBIX_HOME}/lib
endif

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OBJROOT= obj
TARGETROOT= lib

INCLUDES= . ${ORBIXINC} ${OPENBUSINC}/scs ${OPENBUSINC}/openssl-0.9.9
LDIR= ${ORBIXLDIR} ${OPENBUSLIB} ${ORBIXLDIR}

LIBS= it_poa it_art it_ifc it_portable_interceptor scsorbix crypto

SRC= openbus/interceptors/ClientInterceptor.cpp \
     openbus/interceptors/ServerInterceptor.cpp \
     openbus/interceptors/ORBInitializerImpl.cpp \
     stubs/orbix/access_control_serviceC.cxx \
     stubs/orbix/access_control_service_exceptionsC.cxx \
     stubs/orbix/registry_serviceC.cxx \
     stubs/orbix/session_serviceC.cxx \
     stubs/orbix/coreC.cxx \
     stubs/orbix/scsC.cxx \
     openbus.cpp \
     openbus/util/Helper.cpp \
     verbose.cpp

genstubs:
	mkdir -p stubs/orbix
	cd stubs/orbix ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/access_control_service.idl 
	cd stubs/orbix ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/access_control_service_exceptions.idl 
	cd stubs/orbix ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/registry_service.idl
	cd stubs/orbix ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/session_service.idl
	cd stubs/orbix ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/core.idl
	cd stubs/orbix ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/scs.idl
	
sunos58: $(OBJS)
	rm -f lib/SunOS58/libopenbusorbix.a
	CC -xar -instances=extern -o lib/SunOS58/libopenbusorbix.a $(OBJS)
	rm -f lib/SunOS58/libopenbusorbix.so
	CC -G -instances=extern -Kpic -o lib/SunOS58/libopenbusorbix.so $(OBJS)


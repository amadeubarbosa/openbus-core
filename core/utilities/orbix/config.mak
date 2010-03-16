PROJNAME= openbus
LIBNAME= ${PROJNAME}

#Descomente as duas linhas abaixo para o uso em Valgrind.
#DBG=YES
#CPPFLAGS= -fno-inline

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

ifeq ($(TEC_WORDSIZE), TEC_64)
  ORBIXLDIR=${ORBIX_HOME}/lib/lib64
else
  ORBIXLDIR=${ORBIX_HOME}/lib
endif

ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CPPFLAGS= -g +p -KPIC -mt -D_REENTRANT
  ifeq ($(TEC_WORDSIZE), TEC_64)
    CPPFLAGS+= -m64
    ORBIXLDIR=${ORBIX_HOME}/lib/sparcv9
  endif
endif

ORBIX_HOME= ${IT_PRODUCT_DIR}/asp/6.3
ORBIXINC= ${ORBIX_HOME}/include

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

OBJROOT= obj
TARGETROOT= lib

INCLUDES= . ${ORBIXINC} ${OPENBUSINC}/scs/orbix ${OPENBUSINC}/openssl-0.9.9
LDIR= ${ORBIXLDIR} ${OPENBUSLIB} ${ORBIXLDIR}

LIBS= it_poa it_art it_ifc it_portable_interceptor scsorbix crypto

SRC= openbus/common/ClientInterceptor.cpp \
     openbus/common/ServerInterceptor.cpp \
     openbus/common/ORBInitializerImpl.cpp \
     stubs/access_control_serviceC.cxx \
     stubs/registry_serviceC.cxx \
     stubs/session_serviceC.cxx \
     stubs/coreC.cxx \
     openbus.cpp \
     services/RegistryService.cpp \
     verbose.cpp

genstubs:
	mkdir -p stubs
	cd stubs ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/access_control_service.idl 
	cd stubs ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/registry_service.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/session_service.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base  ${OPENBUS_HOME}/idlpath/core.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/scs.idl
	
sunos: $(OBJS)
	rm -f lib/$(TEC_UNAME)/libopenbus.a
	CC $(CPPFLAGS) -xar -instances=extern -o lib/$(TEC_UNAME)/libopenbus.a $(OBJS)
	rm -f lib/$(TEC_UNAME)/libopenbus.so
	CC $(CPPFLAGS) -G -instances=extern -KPIC -o lib/$(TEC_UNAME)/libopenbus.so $(OBJS)


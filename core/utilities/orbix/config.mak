PROJNAME= openbus
LIBNAME= ${PROJNAME}

ifeq "$(TEC_UNAME)" "SunOS58"
  CPPC=CC
  CPPFLAGS= -g +p -KPIC -xarch=v8  -mt -D_REENTRANT
endif

ORBIX_HOME= ${IT_PRODUCT_DIR}/asp/6.3
ORBIXINC= ${ORBIX_HOME}/include
ORBIXLDIR=${ORBIX_HOME}/lib

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= . ${ORBIXINC} ${OPENBUSINC}/scs/orbix
LDIR= ${ORBIXLDIR} ${OPENBUSLIB}

LIBS= it_poa it_art it_ifc it_portable_interceptor scsorbix

SRC= openbus/common/ClientInterceptor.cpp \
     openbus/common/ServerInterceptor.cpp \
     openbus/common/ORBInitializerImpl.cpp \
     stubs/access_control_serviceC.cxx \
     stubs/registry_serviceC.cxx \
     stubs/session_serviceC.cxx \
     stubs/coreC.cxx \
     stubs/scsC.cxx \
     services/AccessControlService.cpp \
     openbus.cpp \
     services/RegistryService.cpp

genstubs:
	mkdir -p stubs
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/access_control_service.idl 
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/registry_service.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/session_service.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/core.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/scs.idl
	
sunos58:
	CC -xar -instances=extern -o lib/SunOS58/libopenbus.a \
        obj/SunOS58/*.o
	CC -G -instances=extern -Kpic -o lib/SunOS58/libopenbus.so \
        obj/SunOS58/*.o

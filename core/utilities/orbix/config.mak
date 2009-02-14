PROJNAME= openbus
LIBNAME= ${PROJNAME}

ORBIX_HOME= /opt/iona/asp/6.3
ORBIXINC= ${ORBIX_HOME}/include
ORBIXLDIR=${ORBIX_HOME}/lib

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= . ${ORBIXINC} ${OPENBUSINC}/scs
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
     services/RegistryService.cpp \
     openbus.cpp

genstubs:
	mkdir -p stubs
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/access_control_service.idl 
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/registry_service.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/session_service.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/core.idl
	cd stubs ; ${ORBIX_HOME}/bin/idl -base -poa ${OPENBUS_HOME}/idlpath/scs.idl
	

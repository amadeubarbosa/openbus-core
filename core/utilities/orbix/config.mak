PROJNAME= openbus
LIBNAME= ${PROJNAME}

ORBIX_HOME= /opt/iona34/asp/6.3
ORBIXINC= ${ORBIX_HOME}/include
ORBIXLDIR=${ORBIX_HOME}/lib

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= . ${ORBIXINC}
LDIR= ${ORBIXLDIR}

LIBS= it_poa it_art it_ifc it_portable_interceptor

SLIB= ${OPENBUSLIB}/libscsorbix.a

SRC= openbus/common/ClientInterceptor.cpp \
     openbus/common/ServerInterceptor.cpp \
     openbus/common/CredentialManager.cpp \
     openbus/common/ORBInitializerImpl.cpp \
     stubs/access_control_serviceC.cxx \
     stubs/registry_serviceC.cxx \
     stubs/session_serviceC.cxx \
     stubs/coreC.cxx \
     stubs/scsC.cxx

genstubs:
	mkdir -p stubs
	cd stubs ; idl -base -poa ${OPENBUS_HOME}/core/idl/access_control_service.idl 
	cd stubs ; idl -base -poa ${OPENBUS_HOME}/core/idl/registry_service.idl
	cd stubs ; idl -base -poa ${OPENBUS_HOME}/core/idl/session_service.idl
	cd stubs ; idl -base -poa ${OPENBUS_HOME}/core/idl/core.idl
	cd stubs ; idl -base -poa ${OPENBUS_HOME}/core/idl/scs.idl
	

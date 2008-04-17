PROJNAME= openbus
LIBNAME= ${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

#Descomente a linha abaixo caso deseje ativar o VERBOSE
DEFINES=VERBOSE

OBJROOT= obj
TARGETROOT= lib

INCLUDES= ${OPENBUSINC}/scs

LIBS= mico2.3.12

SLIB= ${OPENBUSLIB}/libscsmico.a

SRC= common/ClientInterceptor.cpp \
     common/ServerInterceptor.cpp \
     common/CredentialManager.cpp \
     common/ORBInitializerImpl.cpp \
     stubs/access_control_service.cc \
     stubs/registry_service.cc \
     stubs/session_service.cc \
     stubs/core.cc \
     stubs/scs.cc

genstubs:
	mkdir -p stubs
	cd stubs ; idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/core/idl/access_control_service.idl 
	cd stubs ; idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/core/idl/registry_service.idl
	cd stubs ; idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/core/idl/session_service.idl
	cd stubs ; idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/core/idl/core.idl
	cd stubs ; idl --poa --use-quotes --no-paths --typecode --any ${OPENBUS_HOME}/core/idl/scs.idl
	

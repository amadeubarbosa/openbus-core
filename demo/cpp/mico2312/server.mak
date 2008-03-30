PROJNAME=server
APPNAME=server

EXTRA_CONFIG=config

CPPC=${MICOBIN}/mico-c++
LINKER=${MICOBIN}/mico-ld

DEFINES=${VERBOSE}

TARGETROOT=bin
OBJROOT=obj

SRC=${OPENBUS_HOME}/src/cpp/mico/services/access_control_service.cc \
    ${OPENBUS_HOME}/src/cpp/mico/services/scs.cc \
    ${OPENBUS_HOME}/src/cpp/mico/services/core.cc \
    ${OPENBUS_HOME}/src/cpp/mico/services/registry_service.cc \
    ${OPENBUS_HOME}/src/cpp/mico/common/ClientInterceptor.cpp \
    ${OPENBUS_HOME}/src/cpp/mico/common/ServerInterceptor.cpp \
    ${OPENBUS_HOME}/src/cpp/mico/common/ORBInitializerImpl.cpp \
    ${OPENBUS_HOME}/src/cpp/mico/common/CredentialManager.cpp \
    ${OPENBUS_HOME}/src/cpp/mico/scs/core/IComponentImpl.cpp \
    server.cpp \
    hello.cc

INCLUDES= . ${MICOINC} ${OPENBUS_HOME}/include

LDIR= ${MICOLDIR}

LIBS= ${MICOLIB}

PROJNAME=client
APPNAME=client

EXTRA_CONFIG=config

CPPC=${MICOBIN}/mico-c++
LINKER=${MICOBIN}/mico-ld

DEFINES=${VERBOSE}

TARGETROOT=bin
OBJROOT=obj

SRC=${OPENBUS_HOME}/src/openbus/cpp/mico/services/access_control_service.cc \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/services/scs.cc \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/services/core.cc \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/services/registry_service.cc \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/common/ClientInterceptor.cpp \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/common/ServerInterceptor.cpp \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/common/ORBInitializerImpl.cpp \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/common/CredentialManager.cpp \
    ${OPENBUS_HOME}/src/openbus/cpp/mico/scs/core/IComponentImpl.cpp \
    client.cpp \
    hello.cc

INCLUDES= . ${MICOINC} ${OPENBUS_HOME}/include

LDIR= ${MICOLDIR}

LIBS= ${MICOLIB}

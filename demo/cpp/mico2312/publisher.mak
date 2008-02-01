PROJNAME=publisher
APPNAME=publisher

EXTRA_CONFIG=config

DEFINES=${VERBOSE}

TARGETROOT=bin
OBJROOT=obj

SRC=access_control_service.cc \
    scs.cc \
    core.cc \
    registry_service.cc \
    publisher.cpp \
    hello.cc \
    ClientInterceptor.cpp \
    ORBInitializerImpl.cpp \
    ../../../src/cpp/mico/scs/core/IComponentImpl.cpp

INCLUDES= . ${MICOINC} ../../../include

LDIR= ${MICOLDIR}

LIBS= dl pthread ${MICOLIB}


PROJNAME=consumer
APPNAME=consumer

EXTRA_CONFIG=config

DEFINES=${VERBOSE}

TARGETROOT=bin
OBJROOT=obj

SRC=access_control_service.cc \
    scs.cc \
    core.cc \
    registry_service.cc \
    consumer.cpp \
    hello.cc \
    ClientInterceptor.cpp \
    ORBInitializerImpl.cpp

INCLUDES= . ${MICOINC}

LDIR= ${MICOLDIR}

LIBS= dl pthread ${MICOLIB}


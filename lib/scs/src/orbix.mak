PROJNAME= scsorbix
LIBNAME= ${PROJNAME}

#DEFINES=VERBOSE

ORBIX_HOME= /opt/iona34/asp/6.3
ORBIXINC= ${ORBIX_HOME}/include
ORBIXLDIR=${ORBIX_HOME}/lib

INCLUDES= . ../include ${ORBIXINC}
LDIR= ${ORBIXLDIR}

LIBS= it_poa it_art it_ifc it_portable_interceptor

SRC= IComponentOrbix.cpp \
     stubs/scsS.cxx

genstubs:
	mkdir -p stubs
	cd stubs ; idl --poa --use-quotes --no-paths ../../idl/scs.idl


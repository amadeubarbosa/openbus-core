PROJNAME= scsorbix
LIBNAME= ${PROJNAME}

#DEFINES=VERBOSE
ORBIX_HOME= /opt/iona/asp/6.3
ORBIXINC= ${ORBIX_HOME}/include
ORBIXLDIR=${ORBIX_HOME}/lib

INCLUDES= . ../include ${ORBIXINC}
LDIR= ${ORBIXLDIR}

LIBS= it_poa it_art it_ifc it_portable_interceptor

SRC= IComponentOrbix.cpp \
     ComponentBuilder.cpp \
     stubs/scsS.cxx

genstubs:
	mkdir -p stubs
	cd stubs ; idl -base -poa ../../idl/scs.idl


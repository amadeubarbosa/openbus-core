PROJNAME= scsmico
LIBNAME= ${PROJNAME}
MICOHOME= ${HOME}/tools/mico
MICOIDL=${MICOHOME}/idl
MICOLIB=${MICOHOME}/libs
MICOINC=${MICOHOME}/include

INCLUDES= . ../include ${MICOINC}

LDIR= ${MICOLIB}

LIBS= mico2.3.13

SRC= IComponentMico.cpp \
     stubs/scs.cc

genstubs:
	mkdir -p stubs
	cd stubs ; ${MICOIDL}/idl --poa --use-quotes --no-paths ../../idl/scs.idl


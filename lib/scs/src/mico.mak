PROJNAME= scsmico
LIBNAME= ${PROJNAME}

INCLUDES= . ../include

LIBS= mico2.3.12

SRC= IComponentMico.cpp \
     stubs/scs.cc

genstubs:
	mkdir -p stubs
	cd stubs ; idl --poa --use-quotes --no-paths ../../idl/scs.idl


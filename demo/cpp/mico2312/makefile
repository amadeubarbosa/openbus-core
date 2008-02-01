#
# makefile
#

include config

#Comente a linha abaixo para desativar o verbose.
VERBOSE=-DVERBOSE

CC=g++
FLAGS= -Wall -ansi
RM= rm -f

#Debug options (Valgrind)
#FLAGS= -O0 -g -fno-inline

SRCDYN= access_control_service.cc \
    		scs.cc \
				core.cc \
    		registry_service.cc

all: idl publisher consumer run

idl:
	ln -fs ../../../corba_idl/access_control_service.idl
	ln -fs ../../../corba_idl/registry_service.idl
	ln -fs ../../../corba_idl/scs.idl
	ln -fs ../../../corba_idl/core.idl
	${MICOBIN}/idl --no-poa access_control_service.idl
	${MICOBIN}/idl --no-poa registry_service.idl
	${MICOBIN}/idl --poa scs.idl
	${MICOBIN}/idl --no-poa core.idl
	${MICOBIN}/idl --poa hello.idl

publisher:
	${CC} ${FLAGS} -o publisher \
		publisher.cpp \
		hello.cc \
		${SRCDYN} \
		ClientInterceptor.cpp \
		ORBInitializerImpl.cpp \
		../../../src/cpp/mico/scs/core/IComponentImpl.cpp \
		-I. \
		-I${MICOINC} \
		-I../../../include \
		-L${MICOLDIR} \
		-ldl -lpthread -l${MICOLIB} \
		${VERBOSE}

consumer:
	${CC} ${FLAGS} -o consumer \
		consumer.cpp \
		hello.cc \
		${SRCDYN} \
		ClientInterceptor.cpp \
		ORBInitializerImpl.cpp \
		-I. \
		-I${MICOINC} \
		-I../../../include \
		-L${MICOLDIR} \
		-ldl -lpthread -l${MICOLIB} \
		${VERBOSE}

clean:
	${RM} publisher \
				consumer \
				${SRCDYN} \
				access_control_service.h \
				scs.h \
				registry_service.h \
				core.h

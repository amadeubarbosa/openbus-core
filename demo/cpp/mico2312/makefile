#
# makefile
#

include config

#Descomente a linha abaixo para ativar o verbose.
# VERBOSE=-DVERBOSE

CC=g++
FLAGS= -Wall -ansi
RM= rm -f

#Debug options (Valgrind)
#FLAGS= -O0 -g -fno-inline

STUBS= ${OPENBUS_HOME}/src/cpp/mico/services/access_control_service.cc \
				${OPENBUS_HOME}/src/cpp/mico/services/scs.cc \
				${OPENBUS_HOME}/src/cpp/mico/services/core.cc \
				${OPENBUS_HOME}/src/cpp/mico/services/registry_service.cc \
				hello.cc

COMMONS= ${OPENBUS_HOME}/src/cpp/mico/common/ORBInitializerImpl.cpp \
					${OPENBUS_HOME}/src/cpp/mico/common/ClientInterceptor.cpp \
					${OPENBUS_HOME}/src/cpp/mico/common/ServerInterceptor.cpp \
					${OPENBUS_HOME}/src/cpp/mico/common/CredentialManager.cpp \
					${OPENBUS_HOME}/src/cpp/mico/scs/core/IComponentImpl.cpp


all: publisher consumer run

publisher:
	${CC} ${FLAGS} -o publisher \
		-I. \
		-I${OPENBUS_HOME}/include \
		-I${MICOINC} \
		-L${MICOLDIR} \
		publisher.cpp \
		${STUBS} \
		${COMMONS} \
		-ldl -lpthread -l${MICOLIB} \
		${VERBOSE}

consumer:
	${CC} ${FLAGS} -o consumer \
		-I. \
		-I${OPENBUS_HOME}/include \
		-I${MICOINC} \
		-L${MICOLDIR} \
		consumer.cpp \
		${STUBS} \
		${COMMONS} \
		-ldl -lpthread -l${MICOLIB} \
		${VERBOSE}

clean:
	${RM} publisher consumer

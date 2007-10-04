#
# makefile
#

include config

all:
	${MAKE} -C src
	${MAKE} -C tests/acs
	${MAKE} -C tests/rgs
	${MAKE} -C tests/ses

# install:
# 	${MKDIR} -p ${INSTALL_LIB} ${INSTALL_INC}
# 	${CP} src/openbus.a ${INSTALL_LIB}
# 	${CP} src/openbus.h ${INSTALL_INC}
# 	${CP} lua/RemoteFileChannel ${INSTALL_LUA}

clean:
	cd src && ${MAKE} clean
	cd tests/acs && ${MAKE} clean
	cd tests/rgs && ${MAKE} clean
	cd tests/ses && ${MAKE} clean



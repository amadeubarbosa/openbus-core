#
# makefile
#

include config

CP= cp -rf
RM= rm -f
MKDIR= mkdir
RMDIR= rmdir

all:
	${MAKE} -C src

gentests:
	${MAKE} -C tests

install:
# 	${MKDIR} -p ${INSTALL_LIB} ${INSTALL_INC}
# 	${CP} src/ftc.a ${INSTALL_LIB}
# 	${CP} src/ftc.h ${INSTALL_INC}
	${CP} lua/ftc ${INSTALL_TOP_SHARE}
	${CP} lua/oil/builder/csockets.lua ${OIL_SHARE}/builder/
	${CP} lua/loop/thread/CoCSocket.lua ${LOOP_SHARE}/thread/


clean:
	cd src && ${MAKE} clean
	cd tests && ${MAKE} clean

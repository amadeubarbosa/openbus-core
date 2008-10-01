PROJNAME = OpenBUS
APPNAME = servicelauncher

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

SRC = servicelauncher.c

INCLUDES += . \
	    ${OPENBUSINC}/oil04 \
            ${OPENBUSINC}/luasocket2 \
            ${OPENBUSINC}/lposix \
            ${OPENBUSINC}/luuid \
            ${OPENBUSINC}/lce \
            ${OPENBUSINC}/lualdap-1.0.1 \
            ${OPENBUSINC}/scs

LDIR += ${OPENBUSLIB}

USE_LUA51 = YES
NO_SCRIPTS = YES

#############################
# Usa bibliotecas dinâmicas #
#############################
LIBS += oilall scsall luasocket lposix luuid lce lualdap

LIBS += dl uuid crypto ldap

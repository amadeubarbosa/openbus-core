PROJNAME = OpenBUS
APPNAME = servicelauncher

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

SRC = servicelauncher.c

INCLUDES += . ${OPENBUSINC}/oil04 ${OPENBUSINC}/luasocket2 ${OPENBUSINC}/lposix ${OPENBUSINC}/luuid ${OPENBUSINC}/lce ${OPENBUSINC}/lualdap-1.0.1
LDIR += ${OPENBUSLIB}

USE_LUA51 = YES
NO_SCRIPTS = YES

#############################
# Usa bibliotecas estáticas #
#############################
#SLIB += liboilall.a libluasocket.a liblposix.a libluuid.a liblce.a liblualdap.a

#############################
# Usa bibliotecas dinâmicas #
#############################
LIBS += oilall luasocket lposix luuid lce lualdap

LIBS += dl uuid crypto ldap

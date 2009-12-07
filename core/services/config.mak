PROJNAME = OpenBUS
APPNAME = servicelauncher

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

SRC = servicelauncher.c

INCLUDES += . \
	    ${OPENBUSINC}/oil04 \
            ${OPENBUSINC}/luasocket2 \
            ${OPENBUSINC}/luafilesystem \
            ${OPENBUSINC}/luuid \
            ${OPENBUSINC}/lce \
            ${OPENBUSINC}/lpw \
            ${OPENBUSINC}/lualdap-1.0.1 \
            ${OPENBUSINC}/scs

LDIR += ${OPENBUSLIB}

USE_LUA51 = YES
NO_SCRIPTS = YES

#############################
# Usa bibliotecas dinâmicas #
#############################

LIBS += dl crypto ldap
ifneq "$(TEC_SYSNAME)" "Darwin"
	LIBS += uuid
endif
ifeq "$(TEC_SYSNAME)" "Linux"
	LFLAGS = -Wl,-E
endif

LIBS = oilall scsall luasocket lfs luuid lce lpw lualdap

# SLIB += ${OPENBUSLIB}/liboilall.a
# SLIB += ${OPENBUSLIB}/libscsall.a
# SLIB += ${OPENBUSLIB}/libluasocket.a
# SLIB += ${OPENBUSLIB}/liblfs.a
# SLIB += ${OPENBUSLIB}/libluuid.a
# SLIB += ${OPENBUSLIB}/liblce.a
# SLIB += ${OPENBUSLIB}/liblualdap.a

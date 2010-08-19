PROJNAME = OpenBUS
APPNAME = servicelauncher

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

SRC = servicelauncher.c

INCLUDES += . \
	    ${OPENBUSINC}/oil-0.5-beta-obv \
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

LIBS = oilall scsall luasocket lfs luuid lce lpw lualdap luaopenbus
LIBS += dl crypto ldap
ifneq "$(TEC_SYSNAME)" "Darwin"
	LIBS += uuid
endif
ifeq "$(TEC_SYSNAME)" "Linux"
	LFLAGS = -Wl,-E
endif
ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  CFLAGS= -g -KPIC -mt -D_REENTRANT
  ifeq ($(TEC_WORDSIZE), TEC_64)
    CFLAGS+= -m64
  endif
  LFLAGS= $(CFLAGS) -xildoff
  LIBS += rt
endif

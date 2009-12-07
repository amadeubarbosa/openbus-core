PROJNAME= OpenBus
APPNAME= acs

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
LUA_FLAGS += -e 'package.path="./?.lua;../../?.lua;"..package.path'

OPENBUSLIB= ${OPENBUS_HOME}/libpath/${TEC_UNAME} 
OPENBUSINC= ${OPENBUS_HOME}/incpath

PRECMP_DIR= ../obj/acs/${TEC_UNAME}
PRECMP_LUA= ${OPENBUS_HOME}/libpath/lua/5.1/precompiler.lua
PRECMP_FLAGS= -p ACCESSCONTROL_SERVICE -o acs -d ${PRECMP_DIR} -n

PRELOAD_LUA= ${OPENBUS_HOME}/libpath/lua/5.1/preloader.lua
PRELOAD_FLAGS= -p ACCESSCONTROL_SERVICE -o acspreloaded -d ${PRECMP_DIR}

ACS_LUA= $(addprefix core.services.accesscontrol.,\
	CredentialDB \
	LDAPLoginPasswordValidator \
	LoginPasswordValidator \
	TestLoginPasswordValidator \
	AccessControlService \
	AccessControlServer )

${PRECMP_DIR}/acs.c: ${ACS_LUA}
	$(LUABIN) $(LUA_FLAGS) $(PRECMP_LUA)   $(PRECMP_FLAGS) $(ACS_LUA) 

${PRECMP_DIR}/acspreloaded.c: ${PRECMP_DIR}/acs.c
	$(LUABIN) $(LUA_FLAGS) $(PRELOAD_LUA)  $(PRELOAD_FLAGS) -i ${PRECMP_DIR} acs.h

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

SRC= ${PRECMP_DIR}/acs.c ${PRECMP_DIR}/acspreloaded.c accesscontrol.c

INCLUDES= . \
        ${PRECMP_DIR} \
        ${OPENBUSINC}/oil04 \
        ${OPENBUSINC}/luasocket2 \
        ${OPENBUSINC}/luafilesystem \
        ${OPENBUSINC}/luuid \
        ${OPENBUSINC}/lce \
        ${OPENBUSINC}/lualdap-1.0.1 \
        ${OPENBUSINC}/scs

LDIR += ${OPENBUSLIB}

USE_LUA51=YES
NO_SCRIPTS=YES
USE_NODEPEND=YES

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

LIBS = oilall scsall luasocket lfs luuid lce lualdap

# SLIB += ${OPENBUSLIB}/liboilall.a
# SLIB += ${OPENBUSLIB}/libscsall.a
# SLIB += ${OPENBUSLIB}/libluasocket.a
# SLIB += ${OPENBUSLIB}/liblfs.a
# SLIB += ${OPENBUSLIB}/libluuid.a
# SLIB += ${OPENBUSLIB}/liblce.a
# SLIB += ${OPENBUSLIB}/liblualdap.a

.PHONY: clean-custom
clean-custom-obj:
	rm -f ${PRECMP_DIR}/*.c
	rm -f ${PRECMP_DIR}/*.h

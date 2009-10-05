PROJNAME= OpenBus
APPNAME= rgs

LUABIN= ${LUA51}/bin/${TEC_UNAME}/lua5.1
LUA_FLAGS += -e 'package.path="./?.lua;../../?.lua;"..package.path'

OPENBUSLIB= ${OPENBUS_HOME}/libpath/${TEC_UNAME} 
OPENBUSINC= ${OPENBUS_HOME}/incpath

PRECMP_DIR= ../obj/rgs/${TEC_UNAME}
PRECMP_LUA= ${OPENBUS_HOME}/libpath/lua/5.1/precompiler.lua
PRECMP_FLAGS= -p REGISTRY_SERVICE -o rgs -d ${PRECMP_DIR} -n

PRELOAD_LUA= ${OPENBUS_HOME}/libpath/lua/5.1/preloader.lua
PRELOAD_FLAGS= -p REGISTRY_SERVICE -o rgspreloaded -d ${PRECMP_DIR}

RGS_LUA= $(addprefix core.services.registry.,\
        OffersDB \
        RegistryService \
        RegistryServer )

${PRECMP_DIR}/rgs.c: ${RGS_LUA}
	$(LUABIN) $(LUA_FLAGS) $(PRECMP_LUA)   $(PRECMP_FLAGS) $(RGS_LUA) 

${PRECMP_DIR}/rgspreloaded.c: ${PRECMP_DIR}/rgs.c
	$(LUABIN) $(LUA_FLAGS) $(PRELOAD_LUA)  $(PRELOAD_FLAGS) -i ${PRECMP_DIR} rgs.h

#Descomente a linha abaixo caso deseje ativar o VERBOSE
#DEFINES=VERBOSE

SRC= ${PRECMP_DIR}/rgs.c ${PRECMP_DIR}/rgspreloaded.c registry.c

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

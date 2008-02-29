INSTALL_DIR=.

BIN_DIR=$(INSTALL_DIR)/bin
CONF_DIR=$(INSTALL_DIR)/conf
CORBA_IDL_DIR=$(INSTALL_DIR)/corba_idl

CORE_DIR=$(INSTALL_DIR)/core

COMPONENTS_DIR=$(INSTALL_DIR)/components
ACCESS_CONTROL_SERVICE_DIR=$(COMPONENTS_DIR)/access_control_service
REGISTRY_SERVICE_DIR=$(COMPONENTS_DIR)/registry_service
SESSION_SERVICE_DIR=$(COMPONENTS_DIR)/session_service

include config

all: libs idl bins

rebuild: clean all

clean: clean-libs clean-bins
	@rm -rf ${OPENBUS_HOME}/libpath
#	@rm -rf ${OPENBUS_HOME}/bin
	@rm -rf $(CORBA_IDL_DIR)

#reinstall:	clean	install

doc:
	@(cd docs/idl; doxygen openbus.dox)
	@(mkdir -p docs/lua; luadoc --nofiles -d docs/lua `find src/lua -name '*.lua'`)

idl:
	@ln -fs src/corba_idl

clean-libs:
	@(for lib_dir in lib/lua/* ; do \
		( cd $$lib_dir ; make clean ); \
	done)

usrlibs:
	cd src/cpp/oil ; `which tecmake`

libs:
#	@ls lib/lua | xargs -I ksh -c "cd lib/lua/{}; echo 'Compilando {}...'; make" 
	if !(test -e ${LUA51}/lib/${TEC_UNAME}) ; then \
		mkdir ${LUA51}/lib/${TEC_UNAME} ; \
		cp ${LUA51}/lib/liblua.a ${LUA51}/lib/${TEC_UNAME}/liblua5.1.a ; \
	fi \

	if !(test -e ${LUA51}/include/luasocket.h) ; then \
		cp ${LUASOCKET2LIB}/luasocket.h ${LUA51}/include ; \
	fi \

	if !(test -e ${LUA51}/lib/libluasocket.so) ; then \
		cp ${LUASOCKET2LIB}/${LUASOCKETSO} ${LUA51}/lib/libluasocket.so ; \
	fi \

	if !(test -e ${LUASOCKET2LIB}/libluasocket.a) ; then \
		ar rcu ${LUASOCKET2LIB}/libluasocket.a ${LUASOCKET2LIB}/auxiliar.o ${LUASOCKET2LIB}/buffer.o ${LUASOCKET2LIB}/except.o ${LUASOCKET2LIB}/inet.o ${LUASOCKET2LIB}/io.o ${LUASOCKET2LIB}/luasocket.o ${LUASOCKET2LIB}/mime.o ${LUASOCKET2LIB}/options.o ${LUASOCKET2LIB}/select.o  ${LUASOCKET2LIB}/tcp.o ${LUASOCKET2LIB}/timeout.o ${LUASOCKET2LIB}/udp.o ${LUASOCKET2LIB}/usocket.o ; \
		ranlib ${LUASOCKET2LIB}/libluasocket.a ; \
	fi \
	
	@(for lib_dir in lib/lua/* ; do \
		echo ; echo "Compilando $$lib_dir " ; \
		( cd $$lib_dir ; make ); \
	done)
	cp -rf src/lua/scs ${LUA51}/share/lua/5.1

clean-bins:
	@cd src/c ; (for service in ../lua/openbus/services/* ; do \
	export mkfile=`echo $$service | cut -d/ -f5` ; \
		if  test -e $$mkfile.mak ;  then \
			echo ; echo "Limpando serviço $$service" ; \
			`which tecmake` MF=$$mkfile clean-all ; \
	fi \
	done)

bins:
	@cd src/c ; (for service in ../lua/openbus/services/* ; do \
	export mkfile=`echo $$service | cut -d/ -f5` ; \
		if  test -e $$mkfile.mak ;  then \
			echo ; echo "Compilando serviço $$service" ; \
			`which tecmake` MF=$$mkfile; \
	fi \
	done)

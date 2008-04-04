INSTALL_DIR=.

BIN_DIR=$(INSTALL_DIR)/bin
CONF_DIR=$(INSTALL_DIR)/conf
CORBA_IDL_DIR=$(INSTALL_DIR)/corba_idl

CORE_DIR=$(INSTALL_DIR)/core

COMPONENTS_DIR=$(INSTALL_DIR)/components
ACCESS_CONTROL_SERVICE_DIR=$(COMPONENTS_DIR)/access_control_service
REGISTRY_SERVICE_DIR=$(COMPONENTS_DIR)/registry_service
SESSION_SERVICE_DIR=$(COMPONENTS_DIR)/session_service

all: libs bins idl

rebuild: clean all

clean: clean-libs clean-bins
	@rm -rf ${OPENBUS_HOME}/libpath
#	@rm -rf ${OPENBUS_HOME}/bin
	@rm -rf $(CORBA_IDL_DIR)

#reinstall:	clean	install

doc:
	@(cd docs/idl; doxygen openbus.dox)
	@(mkdir -p docs/lua; luadoc --nofiles -d docs/lua `find src/openbus/lua -name '*.lua'`)

idl:
	@ln -fs src/openbus/corba_idl

clean-libs:
	@(for lib_dir in lib/lua/* ; do \
		( cd $$lib_dir ; make clean ); \
	done)

usrlibs:
	cd src/openbus/cpp/oil ; tecmake

libs:
#	@ls lib/lua | xargs -I ksh -c "cd lib/lua/{}; echo 'Compilando {}...'; make" 
	@(for lib_dir in lib/lua/* ; do \
		echo ; echo "Compilando $$lib_dir " ; \
		( cd $$lib_dir ; make ); \
	done)

clean-bins:
	@cd src/openbus/c ; (for service in ../lua/openbus/services/* ; do \
	export mkfile=`echo $$service | cut -d/ -f5` ; \
		if  test -e $$mkfile.mak ;  then \
			echo ; echo "Limpando servi�o $$service" ; \
			`which tecmake` MF=$$mkfile clean-all ; \
	fi \
	done)

bins:
	@cd src/openbus/c ; (for service in ../lua/openbus/services/* ; do \
	export mkfile=`echo $$service | cut -d/ -f5` ; \
		if  test -e $$mkfile.mak ;  then \
			echo ; echo "Compilando servi�o $$service" ; \
			`which tecmake` MF=$$mkfile; \
	fi \
	done)

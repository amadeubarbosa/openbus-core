INSTALL_DIR=.

BIN_DIR=$(INSTALL_DIR)/bin
CONF_DIR=$(INSTALL_DIR)/conf
CORBA_IDL_DIR=$(INSTALL_DIR)/corba_idl

CORE_DIR=$(INSTALL_DIR)/core

COMPONENTS_DIR=$(INSTALL_DIR)/components
ACCESS_CONTROL_SERVICE_DIR=$(COMPONENTS_DIR)/access_control_service
REGISTRY_SERVICE_DIR=$(COMPONENTS_DIR)/registry_service
SESSION_SERVICE_DIR=$(COMPONENTS_DIR)/session_service

all: idl bins

rebuild: clean all

clean: clean-bins
	@rm -rf ${OPENBUS_HOME}/libpath
#	@rm -rf ${OPENBUS_HOME}/bin
	@rm -rf $(CORBA_IDL_DIR)

#reinstall:	clean	install

doc:
	@(cd docs/idl; doxygen openbus.dox)
	@(mkdir -p docs/lua; luadoc --nofiles -d docs/lua `find src/openbus/lua -name '*.lua'`)

idl:
	@ln -fs src/openbus/corba_idl

usrlibs:
	cd src/openbus/cpp/oil ; tecmake

clean-bins:
	@cd src/openbus/c ; (for service in ../lua/openbus/services/* ; do \
	export mkfile=`echo $$service | cut -d/ -f5` ; \
		if  test -e $$mkfile.mak ;  then \
			echo ; echo "Limpando serviço $$service" ; \
			`which tecmake` MF=$$mkfile clean-all ; \
	fi \
	done)

bins:
	@cd src/openbus/c ; (for service in ../lua/openbus/services/* ; do \
	export mkfile=`echo $$service | cut -d/ -f5` ; \
		if  test -e $$mkfile.mak ;  then \
			echo ; echo "Compilando serviço $$service" ; \
			`which tecmake` MF=$$mkfile; \
	fi \
	done)

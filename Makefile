INSTALL_DIR=.

BIN_DIR=$(INSTALL_DIR)/bin
CONF_DIR=$(INSTALL_DIR)/conf
CORBA_IDL_DIR=$(INSTALL_DIR)/corba_idl

CORE_DIR=$(INSTALL_DIR)/core

COMPONENTS_DIR=$(INSTALL_DIR)/components
ACCESS_CONTROL_SERVICE_DIR=$(COMPONENTS_DIR)/access_control_service
REGISTRY_SERVICE_DIR=$(COMPONENTS_DIR)/registry_service
SESSION_SERVICE_DIR=$(COMPONENTS_DIR)/session_service

#install: install_bin \
#         install_conf \
#         install_corba_idl \
#         install_core \
#         install_components
#
#install_bin:
#	mkdir -p $(BIN_DIR)
#	cp bin/*.sh $(BIN_DIR)
#
#install_conf:
#	mkdir -p $(CONF_DIR)
#	cp conf/*.lua $(CONF_DIR)
#
#install_corba_idl:
#	mkdir -p $(CORBA_IDL_DIR)
#	cp `find src -name '*.idl'` $(CORBA_IDL_DIR)
#
#install_core:
#	mkdir -p $(CORE_DIR)
#	cp conf/config $(CONF_DIR)
#	cp src/core/lua/*.lua $(CORE_DIR)
#
#install_components:
#	mkdir -p $(ACCESS_CONTROL_SERVICE_DIR)
#	cp `find src/components/access_control_service -name '*.lua'` $(ACCESS_CONTROL_SERVICE_DIR)
#	mkdir -p $(REGISTRY_SERVICE_DIR)
#	cp `find src/components/registry_service -name '*.lua'` $(REGISTRY_SERVICE_DIR)
#	mkdir -p $(SESSION_SERVICE_DIR)
#	cp `find src/components/session_service -name '*.lua'` $(SESSION_SERVICE_DIR)

all:
	@echo "Nenhum alvo definido"
clean: clean-libs
	@rm -rf ${OPENBUS_HOME}/libpath
	@rm -rf $(CORBA_IDL_DIR)

#reinstall:	clean	install

doc:
	cd docs/idl; doxygen openbus.dox

idl:
	@mkdir -p $(CORBA_IDL_DIR)
#	@cd $(CORBA_IDL_DIR) ; find ../src -type f -name "*.idl" | xargs -I{} echo {}
	@cd $(CORBA_IDL_DIR) ; (for idl_file in `find ../src -name '*.idl'` ; do \
      ln -s $$idl_file . ; \
    done)

clean-libs:
	@(for lib_dir in lib/lua/* ; do \
      ( cd $$lib_dir/src ; tecmake clean); \
    done)

libs:
#	@ls lib/lua | xargs -I ksh -c "cd lib/lua/{}; echo 'Compilando {}...'; make" 
	@(for lib_dir in lib/lua/* ; do \
      echo ; echo "Compilando $$lib_dir " ; \
      ( cd $$lib_dir/src ; tecmake ); \
    done)


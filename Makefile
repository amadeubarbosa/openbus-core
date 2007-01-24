INSTALL_DIR=install

BIN_DIR=$(INSTALL_DIR)/bin
CONF_DIR=$(INSTALL_DIR)/conf
CORBA_IDL_DIR=$(INSTALL_DIR)/corba_idl

CORE_DIR=$(INSTALL_DIR)/core

COMPONENTS_DIR=$(INSTALL_DIR)/components
ACCESS_CONTROL_SERVICE_DIR=$(COMPONENTS_DIR)/access_control_service
REGISTRY_SERVICE_DIR=$(COMPONENTS_DIR)/registry_service
SESSION_SERVICE_DIR=$(COMPONENTS_DIR)/session_service

install:
	mkdir -p $(INSTALL_DIR)
	mkdir -p $(BIN_DIR)
	cp bin/*.sh $(BIN_DIR)
	mkdir -p $(CONF_DIR)
	cp `find conf -name '*.lua'` $(CONF_DIR)
	mkdir -p $(CORBA_IDL_DIR)
	cp `find . -name '*.idl'` $(CORBA_IDL_DIR)
	mkdir -p $(CORE_DIR)
	cp `find src/core -name '*.lua'` $(CORE_DIR)
	mkdir -p $(ACCESS_CONTROL_SERVICE_DIR)
	cp `find src/components/access_control_service -name '*.lua'` $(ACCESS_CONTROL_SERVICE_DIR)
	mkdir -p $(REGISTRY_SERVICE_DIR)
	cp `find src/components/registry_service -name '*.lua'` $(REGISTRY_SERVICE_DIR)
	mkdir -p $(SESSION_SERVICE_DIR)
	cp `find src/components/session_service -name '*.lua'` $(SESSION_SERVICE_DIR)

clean:
	rm -rf $(INSTALL_DIR)

reinstall:	clean	install

doc:
	(cd docs/idl; doxygen openbus.dox)

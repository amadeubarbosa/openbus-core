/*
** openbus.cpp
*/

#include "openbus.h"

#include <omg/orb.hh>
#include <it_ts/thread.h>
#include <sstream>
#include <stdio.h>
#include <string.h>

namespace openbus {
  Openbus::RenewLeaseThread::RenewLeaseThread(Openbus* _bus) {
    bus = _bus;
  }

  void* Openbus::RenewLeaseThread::run() {
    unsigned long time;
    while (true) {
      time = ((bus->timeRenewing)/2)*1000;
      IT_CurrentThread::sleep(time);
      bus->accessControlService->renewLease(*bus->credential, bus->lease);
    }
    return 0;
  }

  Openbus* Openbus::instance = 0;
  common::CredentialManager* Openbus::credentialManager = 0;
  common::ORBInitializerImpl* Openbus::ini = 0;
  CORBA::ORB* Openbus::orb = CORBA::ORB::_nil();
  PortableServer::POA* Openbus::poa = 0;
  scs::core::ComponentBuilder* Openbus::componentBuilder = 0;
  PortableServer::POAManager_var Openbus::poa_manager = 0;

  Openbus::Openbus() {
    credentialManager = new common::CredentialManager;
    ini = new common::ORBInitializerImpl(credentialManager);
    PortableInterceptor::register_orb_initializer(ini);
    hostBus = (char*) "";
    portBus = 2089;
  }

  Openbus::~Openbus() {
    delete credentialManager;
    delete ini;
    delete componentBuilder;
  }

  Openbus* Openbus::getInstance() {
    if (instance == 0) {
      instance = new Openbus;
    }
    return instance;
  }

  void Openbus::run() {
    orb->run();
  }

  void Openbus::init(int argc, char** argv) {
    orb = CORBA::ORB_init(argc, argv);
    CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
    poa = PortableServer::POA::_narrow(poa_obj);
    poa_manager = poa->the_POAManager();
    poa_manager->activate();
    componentBuilder = new scs::core::ComponentBuilder(orb, poa);
    for (short idx = 1; idx < argc; idx++) {
      if (!strcmp(argv[idx], "-OpenbusHost")) {
        idx++;
        hostBus = argv[idx];
      } else if (!strcmp(argv[idx], "-OpenbusPort")) {
        idx++;
        portBus = atoi(argv[idx]);
      }
    }
  }

  void Openbus::init(int argc, char** argv, CORBA::ORB* _orb, PortableServer::POA* _poa) {
    orb = _orb;
    poa = _poa;
    componentBuilder = new scs::core::ComponentBuilder(orb, poa);
  }

  scs::core::ComponentBuilder* Openbus::getComponentBuilder() {
    return componentBuilder;
  }

  common::ServerInterceptor* Openbus::getServerInterceptor() {
    return ini->getServerInterceptor();
  }

  common::CredentialManager* Openbus::getCredentialManager() {
    return credentialManager;
  }

  openbus::services::AccessControlService* Openbus::getAccessControlService() {
    return accessControlService;
  }

  Credential* Openbus::getCredential() {
    return credential;
  }

  Lease Openbus::getLease() {
    return lease;
  }

  openbus::services::RegistryService* Openbus::connect(const char* host, unsigned short port, const char* user, \
        const char* password) throw (COMMUNICATION_FAILURE, LOGIN_FAILURE)
  {
  #ifdef VERBOSE
    cout << "[Openbus::connect() BEGIN]" << endl;
  #endif
    try {
    #ifdef VERBOSE
      cout << "\thost = "<<  host << endl;
      cout << "\tport = "<<  port << endl;
      cout << "\tuser = "<<  user << endl;
      cout << "\tpassword = "<<  password << endl;
      cout << "\torb = "<<  orb << endl;
    #endif
      accessControlService = new openbus::services::AccessControlService(host, port, orb);
      IAccessControlService* iAccessControlService = accessControlService->getStub();
    #ifdef VERBOSE
      cout << "\tiAccessControlService = "<<  iAccessControlService << endl;
    #endif
      if (!iAccessControlService->loginByPassword(user, password, credential, lease)) {
        throw LOGIN_FAILURE();
      } else {
        hostBus = (char*) host;
        portBus = port;
        credentialManager->setValue(credential);
        timeRenewing = lease;
        RenewLeaseThread* renewLeaseThread = new RenewLeaseThread(this);
        renewLeaseIT_Thread = IT_ThreadFactory::smf_start(*renewLeaseThread, IT_ThreadFactory::attached, 0);
        registryService = accessControlService->getRegistryService();
        return registryService;
      }
    } catch (const CORBA::SystemException& systemException) {
      throw COMMUNICATION_FAILURE();
    }
  #ifdef VERBOSE
    cout << "[Openbus::connect() END]" << endl << endl;
  #endif
  }

  openbus::services::RegistryService* Openbus::connect(const char* user, const char* password) \
        throw (COMMUNICATION_FAILURE, LOGIN_FAILURE)
  {
    return connect(hostBus, portBus, user, password);
  }

  bool Openbus::logout() {
    return accessControlService->logout(*credential);
  }
}

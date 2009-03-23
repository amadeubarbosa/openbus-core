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
  common::ORBInitializerImpl* Openbus::ini = 0;

  Openbus::RenewLeaseThread::RenewLeaseThread(Openbus* _bus) {
    bus = _bus;
  }

  void* Openbus::RenewLeaseThread::run() {
    unsigned long time;
  #ifdef VERBOSE
    cout << "[Openbus::RenewLeaseThread::run() BEGIN]" << endl;
  #endif
    while (true) {
      time = ((bus->timeRenewing)/2)*300;
      IT_CurrentThread::sleep(time);
      bus->mutex->lock();
      if (bus->connectionState == CONNECTED) {
      #ifdef VERBOSE
        cout << "\t[Renovando credencial...]" << endl;
      #endif
        bus->accessControlService->renewLease(*bus->credential, bus->lease);
      }
      bus->mutex->unlock();
    }
  #ifdef VERBOSE
    cout << "[Mecanismo de renovação de credencial *desativado*...]" << endl;
    cout << "[Openbus::RenewLeaseThread::run() END]" << endl;
  #endif
    return 0;
  }

  void Openbus::commandLineParse(int argc, char** argv) {
    for (short idx = 1; idx < argc; idx++) {
      if (!strcmp(argv[idx], "-OpenbusHost")) {
        idx++;
        hostBus = (char*) malloc(sizeof(char) * strlen(argv[idx]) + 1);
        hostBus = (char*) memcpy(hostBus, argv[idx], strlen(argv[idx]) + 1);
      } else if (!strcmp(argv[idx], "-OpenbusPort")) {
        idx++;
        portBus = atoi(argv[idx]);
      }
    }
  }

  void Openbus::initializeHostPort() {
    hostBus = (char*) "";
    portBus = 2089;
    mutex = new IT_Mutex();
  }

  void Openbus::createOrbPoa() {
    orb = CORBA::ORB_init(_argc, _argv);
    CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
    poa = PortableServer::POA::_narrow(poa_obj);
    poa_manager = poa->the_POAManager();
    poa_manager->activate();
  }

  void Openbus::registerInterceptors() {
    ini = new common::ORBInitializerImpl();
    PortableInterceptor::register_orb_initializer(ini);
  }

  void Openbus::newState() {
    connectionState = DISCONNECTED;
    credential = 0;
    lease = 0;
    registryService = 0;
    accessControlService = 0;
  }

  Openbus::Openbus(
    int argc,
    char** argv)
  {
    _argc = argc;
    _argv = argv;
    newState();
    if (ini == 0) {
      cout << "Registrando interceptadores ..." << endl;
      registerInterceptors();
    }
    initializeHostPort();
    commandLineParse(_argc, _argv);
  }

  Openbus::Openbus(
    int argc,
    char** argv,
    char* host,
    unsigned short port)
  {
    _argc = argc;
    _argv = argv;
    newState();
    if (ini == 0) {
      cout << "Registrando interceptadores ..." << endl;
      registerInterceptors();
    }
    initializeHostPort();
    commandLineParse(_argc, _argv);
    hostBus = (char*) malloc(sizeof(char) * strlen(host) + 1);
    hostBus = (char*) memcpy(hostBus, host, strlen(host) + 1);
    portBus = port;
  }

  Openbus::~Openbus() {
    delete componentBuilder;
    delete mutex;
    delete hostBus;
  }

  void Openbus::init() {
    createOrbPoa();
    componentBuilder = new scs::core::ComponentBuilder(orb, poa);
  }

  void Openbus::init(
    CORBA::ORB_ptr _orb,
    PortableServer::POA* _poa)
  {
    orb = _orb;
    poa = _poa;
    componentBuilder = new scs::core::ComponentBuilder(orb, poa);
  }

  scs::core::ComponentBuilder* Openbus::getComponentBuilder() {
    return componentBuilder;
  }

  Credential_var Openbus::getCredentialIntercepted() {
    return ini->getServerInterceptor()->getCredential();
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

  openbus::services::RegistryService* Openbus::connect(
    const char* user,
    const char* password)
    throw (COMMUNICATION_FAILURE, LOGIN_FAILURE)
  {
  #ifdef VERBOSE
    cout << "[Openbus::connect() BEGIN]" << endl;
  #endif
    if (connectionState == DISCONNECTED) {
      try {
      #ifdef VERBOSE
        cout << "\thost = "<<  hostBus << endl;
        cout << "\tport = "<<  portBus << endl;
        cout << "\tuser = "<<  user << endl;
        cout << "\tpassword = "<<  password << endl;
        cout << "\torb = "<<  orb << endl;
      #endif
        if (accessControlService == 0) {
          accessControlService = new openbus::services::AccessControlService(hostBus, portBus, orb);
        }
        IAccessControlService* iAccessControlService = accessControlService->getStub();
      #ifdef VERBOSE
        cout << "\tiAccessControlService = "<<  iAccessControlService << endl;
      #endif
        mutex->lock();
        if (!iAccessControlService->loginByPassword(user, password, credential, lease)) {
          mutex->unlock();
          throw LOGIN_FAILURE();
        } else {
        #ifdef VERBOSE
          cout << "\tCrendencial recebida: " << credential->identifier << endl;
          cout << "\tAssociando credencial " << credential << " ao ORB " << orb << endl;
        #endif
          connectionState = CONNECTED;
          openbus::common::ClientInterceptor::credentials[orb] = &credential;
          timeRenewing = lease;
          mutex->unlock();
          RenewLeaseThread* renewLeaseThread = new RenewLeaseThread(this);
          renewLeaseIT_Thread = IT_ThreadFactory::smf_start(*renewLeaseThread, IT_ThreadFactory::attached, 0);
          registryService = accessControlService->getRegistryService();
          return registryService;
        }
      } catch (const CORBA::SystemException& systemException) {
        mutex->unlock();
        throw COMMUNICATION_FAILURE();
      }
    } else {
      return registryService;
    }
  #ifdef VERBOSE
    cout << "[Openbus::connect() END]" << endl << endl;
  #endif
  }

  bool Openbus::disconnect() {
  #ifdef VERBOSE
    cout << "[Openbus::disconnect() BEGIN]" << endl;
  #endif
    mutex->lock();
    if (connectionState == CONNECTED) {
      bool status = accessControlService->logout(*credential);
      if (status) {
        openbus::common::ClientInterceptor::credentials[orb] = 0;
        delete accessControlService;
        newState();
      } else {
        connectionState = CONNECTED;
      }
    #ifdef VERBOSE
      cout << "[Openbus::disconnect() END]" << endl;
    #endif
      mutex->unlock();
      return status;
    } else {
    #ifdef VERBOSE
      cout << "[Não há conexão a ser desfeita.]" << endl;
      cout << "[Openbus::disconnect() END]" << endl;
    #endif
      mutex->unlock();
      return false;
    }
  }

  void Openbus::run() {
    orb->run();
  }
}

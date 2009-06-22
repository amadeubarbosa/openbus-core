/*
** openbus.cpp
*/

#include "openbus.h"

#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <omg/orb.hh>
#include <it_ts/thread.h>
#include <sstream>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define CHALLENGE_SIZE 36

namespace openbus {
  common::ORBInitializerImpl* Openbus::ini = 0;
  Openbus* Openbus::bus = 0;

  void Openbus::terminationHandlerCallback(long signalType) {
  #ifdef VERBOSE
    cout << "[Openbus::terminationHandlerCallback() BEGIN]" << endl;
  #endif
    bus->disconnect();
    if (!CORBA::is_nil(bus->orb)) {
      bus->orb->shutdown(0);
    }
  #ifdef VERBOSE
    cout << "[Openbus::terminationHandlerCallback() END]" << endl;
  #endif
  }

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
        bus->iLeaseProvider->renewLease(*bus->credential, bus->lease);
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

  void Openbus::initialize() {
    hostBus = (char*) "";
    portBus = 2089;
    orb = 0;
    poa = 0;
    componentBuilder = 0;
    mutex = new IT_Mutex();
  }

  void Openbus::createOrbPoa() {
    orb = CORBA::ORB_init(_argc, _argv);
    getRootPOA();
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
    iAccessControlService = 0;
    iSessionService = 0;
    iLeaseProvider = 0;
  }

  void Openbus::createProxyToIAccessControlService() {
  #ifdef VERBOSE
    cout << "[Openbus::createProxyToIAccessControlService() BEGIN]" << endl;
  #endif
    std::stringstream corbalocACS;
    std::stringstream corbalocLP;
    corbalocACS << "corbaloc::" << hostBus << ":" << portBus << "/ACS";
    corbalocLP << "corbaloc::" << hostBus << ":" << portBus << "/LP";
    CORBA::Object_var objACS = 
      orb->string_to_object(corbalocACS.str().c_str());
    CORBA::Object_var objLP = 
      orb->string_to_object(corbalocLP.str().c_str());
    iAccessControlService = 
      openbusidl::acs::IAccessControlService::_narrow(objACS);
    iLeaseProvider = openbusidl::acs::ILeaseProvider::_narrow(objLP);
    cout << "iLeaseProvider:" << iLeaseProvider << endl;
#ifdef VERBOSE
    cout << "[Openbus::createProxyToIAccessControlService() END]" << endl;
  #endif
  }

  Openbus::Openbus() {
    newState();
    cout << "Registrando interceptadores ..." << endl;
    registerInterceptors();
    initialize();
  }

  Openbus* Openbus::getInstance() {
    if (!bus) {
      bus = new Openbus();
    }
    return bus;
  }

  void Openbus::init(
    int argc,
    char** argv)
  {
    _argc = argc;
    _argv = argv;
    commandLineParse(_argc, _argv);
    createOrbPoa();
    componentBuilder = new scs::core::ComponentBuilder(orb, poa);
  }

  void Openbus::init(
    int argc,
    char** argv,
    char* host,
    unsigned short port)
  {
    init(argc, argv);
    hostBus = (char*) malloc(sizeof(char) * strlen(host) + 1);
    hostBus = (char*) memcpy(hostBus, host, strlen(host) + 1);
    portBus = port;
  }

  bool Openbus::isConnected() {
    if (connectionState == CONNECTED) {
      return true;
    }
    return false;
  }

  Openbus::~Openbus() {
    delete componentBuilder;
    delete mutex;
    delete hostBus;
  }

  CORBA::ORB* Openbus::getORB() {
    return orb;
  }

  PortableServer::POA* Openbus::getRootPOA() {
    if (!poa) {
      CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
      poa = PortableServer::POA::_narrow(poa_obj);
      poa_manager = poa->the_POAManager();
      poa_manager->activate();
    }
    return poa;
  }

  scs::core::ComponentBuilder* Openbus::getComponentBuilder() {
    return componentBuilder;
  }

  Credential_var Openbus::getInterceptedCredential() {
    return ini->getServerInterceptor()->getCredential();
  }

  openbusidl::acs::IAccessControlService* Openbus::getAccessControlService() {
    return iAccessControlService;
  }

  openbus::services::RegistryService* Openbus::getRegistryService() {
    if (!registryService) {
     registryService = new openbus::services::RegistryService(
      iAccessControlService->getRegistryService());
    }
    return registryService;
  } 

  openbusidl::ss::ISessionService* Openbus::getSessionService() 
    throw(NO_CONNECTED, NO_SESSION_SERVICE)
  {
    if (connectionState != CONNECTED) {
      throw NO_CONNECTED();
    } else {
      if (!iSessionService) {
        try {
          openbusidl::rs::FacetList_var facetList = \
            new openbusidl::rs::FacetList();
          facetList->length(1);
          facetList[0] = "ISessionService";
          openbus::services::ServiceOfferList_var serviceOfferList = \
            registryService->find(facetList);
          openbus::services::ServiceOffer serviceOffer = serviceOfferList[0];
          scs::core::IComponent* component = serviceOffer.member;
          CORBA::Object* obj = \
            component->getFacet("IDL:openbusidl/ss/ISessionService:1.0");
          iSessionService = openbusidl::ss::ISessionService::_narrow(obj);
        } catch (CORBA::Exception& e) {
          throw NO_SESSION_SERVICE();
        }
      }
    }
    return iSessionService;
  }

  Credential* Openbus::getCredential() {
    return credential;
  }

  openbus::services::RegistryService* Openbus::connect(
    const char* user,
    const char* password)
    throw (CORBA::SystemException, LOGIN_FAILURE)
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
        if (!iAccessControlService) {
          createProxyToIAccessControlService();
        }
      #ifdef VERBOSE
        cout << "\tiAccessControlService = "<<  iAccessControlService << endl;
      #endif
        mutex->lock();
        if (!iAccessControlService->loginByPassword(user, password, credential,
          lease))
        {
          mutex->unlock();
          throw LOGIN_FAILURE();
        } else {
        #ifdef VERBOSE
          cout << "\tCrendencial recebida: " << credential->identifier << endl;
          cout << "\tAssociando credencial " << credential << " ao ORB " << orb
            << endl;
        #endif
          connectionState = CONNECTED;
          openbus::common::ClientInterceptor::credentials[orb] = &credential;
          timeRenewing = lease;
          mutex->unlock();
          RenewLeaseThread* renewLeaseThread = new RenewLeaseThread(this);
          renewLeaseIT_Thread = IT_ThreadFactory::smf_start(*renewLeaseThread, 
            IT_ThreadFactory::attached, 0);
          registryService = getRegistryService();
          return registryService;
        }
      } catch (const CORBA::SystemException& systemException) {
        mutex->unlock();
        throw;
      }
    } else {
      return registryService;
    }
  #ifdef VERBOSE
    cout << "[Openbus::connect() END]" << endl << endl;
  #endif
  }

  services::RegistryService* Openbus::connect(
    const char* entity,
    const char* privateKeyFilename,
    const char* ACSCertificateFilename)
    throw (CORBA::SystemException, LOGIN_FAILURE, SECURITY_EXCEPTION)
  {
  #ifdef VERBOSE
    cout << "[Openbus::connect() BEGIN]" << endl;
  #endif
    if (connectionState == DISCONNECTED) {
      try {
      #ifdef VERBOSE
        cout << "\thost = "<< hostBus << endl;
        cout << "\tport = "<< portBus << endl;
        cout << "\tentity = "<< entity << endl;
        cout << "\tprivateKeyFilename = "<< privateKeyFilename << endl;
        cout << "\torb = "<< orb << endl;
      #endif
        if (!iAccessControlService) {
          createProxyToIAccessControlService();
        }

      /* Requisição de um "desafio" que somente poderá ser decifrado através
      *  da chave privada da entidade reconhecida pelo barramento.
      */
        openbusidl::OctetSeq* octetSeq =
          iAccessControlService->getChallenge(entity);
        if (octetSeq->length() == 0) {
          throw SECURITY_EXCEPTION(
            "O ACS não encontrou o certificado do serviço.");
        }
        unsigned char* challenge = octetSeq->get_buffer();

      /* Leitura da chave privada da entidade. */
        FILE* fp = fopen(privateKeyFilename, "r");
        if (fp == 0) {
        #ifdef VERBOSE
          cout << "\tNão foi possível abrir o arquivo: " << privateKeyFilename
            << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "Não foi possível abrir o arquivo que armazena a chave privada.");
        }
        EVP_PKEY* privateKey = PEM_read_PrivateKey(fp, 0, 0, 0);
        if (privateKey == 0) {
        #ifdef VERBOSE
          cout << "\tNão foi possível obter a chave privada da entidade."
            << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "Não foi possível obter a chave privada da entidade.");
        }

        int RSAModulusSize = EVP_PKEY_size(privateKey);

      /* Decifrando o desafio. */
        unsigned char* challengePlainText =
          (unsigned char*) malloc(RSAModulusSize);
        RSA_private_decrypt(RSAModulusSize, challenge, challengePlainText,
          privateKey->pkey.rsa, RSA_PKCS1_PADDING);

      /* Leitura do certificado do ACS. */
        FILE* certificateFile = fopen(ACSCertificateFilename, "rb");
        if (certificateFile == 0) {
          free(challengePlainText);
        #ifdef VERBOSE
          cout << "\tNão foi possível abrir o arquivo: " <<
            ACSCertificateFilename << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "Não foi possível abrir o arquivo que armazena o certificado ACS.");
        }
        X509* x509 = d2i_X509_fp(certificateFile, 0);

      /* Obtenção da chave pública do ACS. */
        EVP_PKEY* publicKey = X509_get_pubkey(x509);
        if (publicKey == 0) {
        #ifdef VERBOSE
          cout << "\tNão foi possível obter a chave pública do ACS." << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "Não foi possível obter a chave pública do ACS.");
        }

      /* Reposta ao desafio, ou seja, cifra do desafio utilizando a chave
      *  pública do ACS.
      */
        unsigned char* answer = (unsigned char*) malloc(RSAModulusSize);
        RSA_public_encrypt(CHALLENGE_SIZE, challengePlainText, answer,
          publicKey->pkey.rsa, RSA_PKCS1_PADDING);

        free(challengePlainText);

        openbusidl::OctetSeq_var answerOctetSeq = new openbusidl::OctetSeq(
          (CORBA::ULong) RSAModulusSize, (CORBA::ULong) RSAModulusSize,
          (CORBA::Octet*)answer, 0);

      #ifdef VERBOSE
        cout << "\tiAccessControlService = "<<  iAccessControlService << endl;
      #endif
        mutex->lock();
        if (!iAccessControlService->loginByCertificate(entity, answerOctetSeq,
          credential, lease))
        {
          free(answer);
          mutex->unlock();
          throw LOGIN_FAILURE();
        } else {
          free(answer);
        #ifdef VERBOSE
          cout << "\tCrendencial recebida: " << credential->identifier << endl;
          cout << "\tAssociando credencial " << credential << " ao ORB " << orb
            << endl;
        #endif
          connectionState = CONNECTED;
          openbus::common::ClientInterceptor::credentials[orb] = &credential;
          timeRenewing = lease;
          mutex->unlock();
          RenewLeaseThread* renewLeaseThread = new RenewLeaseThread(this);
          renewLeaseIT_Thread = IT_ThreadFactory::smf_start(*renewLeaseThread,
            IT_ThreadFactory::attached, 0);
          registryService = getRegistryService();
          return registryService;
        }
      } catch (const CORBA::SystemException& systemException) {
        mutex->unlock();
        throw;
      }
    } else {
      return registryService;
    }
  #ifdef VERBOSE
    cout << "[Openbus::connect() END]" << endl;
  #endif
  }


  bool Openbus::disconnect() {
  #ifdef VERBOSE
    cout << "[Openbus::disconnect() BEGIN]" << endl;
  #endif
    mutex->lock();
    if (connectionState == CONNECTED) {
      bool status = iAccessControlService->logout(*credential);
      if (status) {
        openbus::common::ClientInterceptor::credentials[orb] = 0;
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

  void Openbus::finish(bool force) {
    orb->shutdown(force);
    orb->destroy();
  }
}


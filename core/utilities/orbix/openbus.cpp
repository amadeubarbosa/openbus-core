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
#ifdef VERBOSE
  Verbose* Openbus::verbose = 0;
#endif
  common::ORBInitializerImpl* Openbus::ini = 0;
  IT_Mutex Openbus::mutex;
  Openbus* Openbus::bus = 0;
  std::set<Openbus::LeaseExpiredCallback> Openbus::leaseExpiredCallbackSet;
  Openbus::RenewLeaseThread* Openbus::renewLeaseThread = 0;

  void Openbus::terminationHandlerCallback(long signalType) {
  #ifdef VERBOSE
    verbose->print("Openbus::terminationHandlerCallback() BEGIN");
    verbose->indent();
  #endif
    try {
      bus->disconnect();
    } catch(CORBA::Exception& e) {
    #ifdef VERBOSE
      verbose->print(
        "Não foi possível se desconectar corretamente do barramento."); 
    #endif
    }
    if (!CORBA::is_nil(bus->orb)) {
      bus->orb->shutdown(0);
    }
  #ifdef VERBOSE
    verbose->dedent("Openbus::terminationHandlerCallback() END");
  #endif
  }

  void Openbus::localDisconnect() {
    if (iRegistryService) {
      delete iRegistryService;
    }
    if (registryService) {
      delete registryService;
    }
    openbus::common::ClientInterceptor::credential = 0;
    newState();
  }

  Openbus::RenewLeaseThread::RenewLeaseThread() {
  }

  void* Openbus::RenewLeaseThread::run() {
    unsigned int timeRenewing;
  #ifdef VERBOSE
    verbose->print("Openbus::RenewLeaseThread::run() BEGIN");
  #endif
    while (true) {
      mutex.lock();
      if (!bus) {
        mutex.unlock();
        break;
      }
      timeRenewing = bus->timeRenewing;
      mutex.unlock();
      IT_CurrentThread::sleep(timeRenewing);
    #ifdef VERBOSE
      verbose->print("Openbus::RenewLeaseThread::run() RUN");
      verbose->indent();
      stringstream msg;
      msg << "Thread: " << this;
      verbose->print(msg.str());
    #endif
      mutex.lock();
      if (bus && bus->connectionState == CONNECTED) {
      #ifdef VERBOSE
        verbose->print("Renovando credencial...");
      #endif
        try {
          bool status = bus->iLeaseProvider->renewLease(*bus->credential, 
            bus->lease);
          if (!bus->timeRenewingFixe) {
            bus->timeRenewing = (bus->lease/2)*300;
          }
        #ifdef VERBOSE
          stringstream msg;
          msg << "Próximo intervalo de renovação: " << bus->timeRenewing << "ms";
          verbose->print(msg.str());
        #endif
          if (!status) {
          #ifdef VERBOSE
            verbose->print("Não foi possível renovar a credencial!");
          #endif
            std::set<LeaseExpiredCallback>::iterator it;
            for(it = leaseExpiredCallbackSet.begin(); 
                it != leaseExpiredCallbackSet.end();
                it++)
            {
              (*it)();
            } 
          /* "Desconecta" o usuário. */
            bus->localDisconnect();
          } else {
          #ifdef VERBOSE
            verbose->print("Credencial renovada!");
          #endif
          }
        } catch (CORBA::Exception& e) {
        #ifdef VERBOSE
          verbose->print("Não foi possível renovar a credencial!");
        #endif
          std::set<LeaseExpiredCallback>::iterator it;
          for(it = leaseExpiredCallbackSet.begin(); 
              it != leaseExpiredCallbackSet.end();
              it++)
          {
            (*it)();
          } 
        /* "Desconecta" o usuário. ? */
          bus->localDisconnect();
        }
      } else {
        mutex.unlock();
        break;
      }
      mutex.unlock();
    #ifdef VERBOSE
      verbose->dedent("Openbus::RenewLeaseThread::run() SLEEP");
    #endif
    }
  #ifdef VERBOSE
    verbose->print("Mecanismo de renovação de credencial *desativado*...");
    verbose->dedent("Openbus::RenewLeaseThread::run() END");
  #endif
    return 0;
  }

  void Openbus::commandLineParse(int argc, char** argv) {
    timeRenewingFixe = false;
    for (short idx = 1; idx < argc; idx++) {
      if (!strcmp(argv[idx], "-OpenbusHost")) {
        idx++;
        hostBus = argv[idx];
      } else if (!strcmp(argv[idx], "-OpenbusPort")) {
        idx++;
        portBus = atoi(argv[idx]);
      } else if (!strcmp(argv[idx], "-TimeRenewing")) {
        timeRenewing = (unsigned int) atoi(argv[++idx]);
        timeRenewingFixe = true;
      }
    }
  }

  void Openbus::createOrbPoa() {
    orb = CORBA::ORB_init(_argc, _argv);
    getRootPOA();
  }

  void Openbus::registerInterceptors() {
    if (!ini) {
    #ifdef VERBOSE
      verbose->print("Registrando interceptadores ...");
    #endif
      ini = new common::ORBInitializerImpl();
      PortableInterceptor::register_orb_initializer(ini);
    }
  }

  void Openbus::newState() {
    connectionState = DISCONNECTED;
    credential = 0;
    lease = 0;
    registryService = 0;
    iAccessControlService = IAccessControlService::_nil();
    iRegistryService = 0;
    iSessionService = 0;
    iLeaseProvider = ILeaseProvider::_nil();
  }

  void Openbus::initialize() {
    hostBus = "";
    portBus = 2089;
    orb = CORBA::ORB::_nil();
    poa = PortableServer::POA::_nil();
    componentBuilder = 0;
  }

 void Openbus::createProxyToIAccessControlService() {
  #ifdef VERBOSE
    verbose->print("Openbus::createProxyToIAccessControlService() BEGIN");
    verbose->indent();
  #endif
    std::stringstream corbalocACS;
    std::stringstream corbalocLP;
    corbalocACS << "corbaloc::" << hostBus << ":" << portBus << "/ACS";
  #ifdef VERBOSE
    verbose->print("corbaloc ACS: " + corbalocACS.str());
  #endif
    corbalocLP << "corbaloc::" << hostBus << ":" << portBus << "/LP";
  #ifdef VERBOSE
    verbose->print("corbaloc LeaseProvider: " + corbalocLP.str());
  #endif
    CORBA::Object_var objACS = 
      orb->string_to_object(corbalocACS.str().c_str());
    CORBA::Object_var objLP = 
      orb->string_to_object(corbalocLP.str().c_str());
    iAccessControlService = 
      openbusidl::acs::IAccessControlService::_narrow(objACS);
    iLeaseProvider = openbusidl::acs::ILeaseProvider::_narrow(objLP);
  #ifdef VERBOSE
    verbose->dedent("Openbus::createProxyToIAccessControlService() END");
  #endif
  }

  services::RegistryService* Openbus::setRegistryService() {
    if (!registryService) {
      iRegistryService = iAccessControlService->getRegistryService(); 
      registryService = new openbus::services::RegistryService(
        iRegistryService);
    }
    return registryService;
  }

  Openbus::Openbus() {
  #ifdef VERBOSE
    verbose->print("Openbus::Openbus() BEGIN");
    verbose->indent();
  #endif
    newState();
    registerInterceptors();
    initialize();
  #ifdef VERBOSE
    verbose->dedent("Openbus::Openbus() END");
  #endif
  }

  Openbus::~Openbus() {
  #ifdef VERBOSE
    verbose->print("Openbus::~Openbus() BEGIN");
    verbose->indent();
  #endif
    if (componentBuilder) {
    #ifdef VERBOSE
      verbose->print("Deletando objeto componentBuilder...");
    #endif
      delete componentBuilder;
    }
    if (!CORBA::is_nil(orb)) {
    #ifdef VERBOSE
      verbose->print("Desligando o orb...");
    #endif
      orb->shutdown(1);
    }
    mutex.lock();
    bus = 0;
    mutex.unlock();
    if (renewLeaseThread) {
    #ifdef VERBOSE
      verbose->print("Esperando término de execução da Thread de renovação...");
    #endif
      renewLeaseIT_Thread.join();
    #ifdef VERBOSE
      verbose->print("Deletando objeto renewLeaseThread...");
    #endif
      delete renewLeaseThread;
      renewLeaseThread = 0;
    }
  #ifdef VERBOSE
    verbose->dedent("Openbus::~Openbus() END");
  #endif
  }

  Openbus* Openbus::getInstance() {
  #ifdef VERBOSE
    if (!verbose) {
      verbose = new Verbose();
      scs::core::ComponentBuilder::verbose = verbose;
      scs::core::IComponentImpl::verbose = verbose;
      scs::core::IMetaInterfaceImpl::verbose = verbose;
    }
    verbose->print("Openbus::getInstance() BEGIN");
    verbose->indent();
  #endif
    if (!bus) {
    #ifdef VERBOSE
      verbose->print("Criando novo objeto...");
    #endif
      mutex.lock();
      bus = new Openbus();
      mutex.unlock();
    }
  #ifdef VERBOSE
    verbose->dedent("Openbus::getInstance() END");
  #endif
    return bus;
  }

  void Openbus::init(
    int argc,
    char** argv)
  {
  #ifdef VERBOSE
    verbose->print("Openbus::init(int argc, char** argv) BEGIN");
    verbose->indent();
  #endif
    _argc = argc;
    _argv = argv;
    commandLineParse(_argc, _argv);
    createOrbPoa();
    if (!componentBuilder) {
      componentBuilder = new scs::core::ComponentBuilder(orb, poa);
    }
  #ifdef VERBOSE
    verbose->dedent("Openbus::init() END");
  #endif
  }

  void Openbus::init(
    int argc,
    char** argv,
    char* host,
    unsigned short port)
  {
  #ifdef VERBOSE
    verbose->print("Openbus::init(int argc, char** argv, char* host, \
      unsigned short port) BEGIN");
    verbose->indent();
  #endif
    init(argc, argv);
    hostBus = host;
    portBus = port;
  #ifdef VERBOSE
    verbose->dedent("Openbus::init(int argc, char** argv, char* host, \
      unsigned short port) END");
  #endif
  }

  bool Openbus::isConnected() {
  #ifdef VERBOSE
    verbose->print("Openbus::isConnected() BEGIN");
    verbose->indent();
  #endif
    if (connectionState == CONNECTED) {
    #ifdef VERBOSE
      verbose->print("Está conectado.");
      verbose->dedent("Openbus::isConnected() END");
    #endif
      return true;
    }
  #ifdef VERBOSE
    verbose->print("NÃO está conectado.");
    verbose->dedent("Openbus::isConnected() END");
  #endif
    return false;
  }

  CORBA::ORB* Openbus::getORB() {
    return orb;
  }

  PortableServer::POA* Openbus::getRootPOA() {
  #ifdef VERBOSE
    verbose->print("Openbus::getRootPOA() BEGIN");
    verbose->indent();
  #endif
    if (CORBA::is_nil(poa)) {
      CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
      poa = PortableServer::POA::_narrow(poa_obj);
      poa_manager = poa->the_POAManager();
      poa_manager->activate();
    }
  #ifdef VERBOSE
    verbose->dedent("Openbus::getRootPOA() END");
  #endif
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
    return registryService;
  } 

  openbusidl::ss::ISessionService* Openbus::getSessionService() 
    throw(NO_CONNECTED, NO_SESSION_SERVICE)
  {
    if (connectionState != CONNECTED) {
      throw NO_CONNECTED();
    } else {
      if (CORBA::is_nil(iSessionService)) {
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

  void Openbus::setThreadCredential(Credential* credential) {
    this->credential = credential;
    openbus::common::ClientInterceptor::credential = credential;
  }

  bool Openbus::addLeaseExpiredCallback( \
    LeaseExpiredCallback leaseExpiredCallback) 
  {
    std::pair<set<LeaseExpiredCallback>::iterator, bool> ret; 
    ret = leaseExpiredCallbackSet.insert(leaseExpiredCallback);
    return ret.second;
  }

  bool Openbus::removeLeaseExpiredCallback( \
    LeaseExpiredCallback leaseExpiredCallback) 
  {
    return (bool) leaseExpiredCallbackSet.erase(leaseExpiredCallback);
  }

  openbus::services::RegistryService* Openbus::connect(
    const char* user,
    const char* password)
    throw (CORBA::SystemException, LOGIN_FAILURE)
  {
  #ifdef VERBOSE
    verbose->print("Openbus::connect() BEGIN");
    verbose->indent();
  #endif
    if (connectionState == DISCONNECTED) {
      try {
      #ifdef VERBOSE
        std::stringstream portMSG;
        std::stringstream userMSG;
        std::stringstream passwordMSG;
        std::stringstream orbMSG;
        verbose->print("host = " + hostBus);
        portMSG << "port = " << portBus; 
        verbose->print(portMSG.str());
        userMSG << "username = " << user;
        verbose->print(userMSG.str());
        passwordMSG<< "password = " << password;
        verbose->print(passwordMSG.str());
        orbMSG<< "orb = " << &orb;
        verbose->print(orbMSG.str());
      #endif
        if (CORBA::is_nil(iAccessControlService)) {
          createProxyToIAccessControlService();
        }

      #ifdef VERBOSE
        stringstream iACSMSG;
        iACSMSG << "iAccessControlService = " << &iAccessControlService; 
        verbose->print(iACSMSG.str());
      #endif
        mutex.lock();
        if (!iAccessControlService->loginByPassword(user, password, credential,
          lease))
        {
          mutex.unlock();
        #ifdef VERBOSE
          verbose->print("Throwing LOGIN_FAILURE...");
          verbose->dedent("Openbus::connect() END");
        #endif
          throw LOGIN_FAILURE();
        } else {

        #ifdef VERBOSE
          stringstream msg;
          msg << "Associando credencial " << credential << " ao ORB.";
          verbose->print(msg.str());
        #endif
          connectionState = CONNECTED;
          openbus::common::ClientInterceptor::credential = credential;
          if (!timeRenewingFixe) {
            timeRenewing = (lease/2)*300;
          }
          if (!renewLeaseThread) {
            renewLeaseThread = new RenewLeaseThread();
            renewLeaseIT_Thread = IT_ThreadFactory::smf_start(
              *renewLeaseThread, 
              IT_ThreadFactory::attached, 0);
          }
          mutex.unlock();
          registryService = setRegistryService();
        #ifdef VERBOSE
          verbose->dedent("Openbus::connect() END");
        #endif
          return registryService;

        }

      } catch (const CORBA::SystemException& systemException) {
        mutex.unlock();
      #ifdef VERBOSE
        verbose->print("Throwing CORBA::SystemException...");
        verbose->dedent("Openbus::connect() END");
      #endif
        throw;
      }
    } else {
    #ifdef VERBOSE
      verbose->print("Já há uma conexão ativa.");
      verbose->dedent("Openbus::connect() END");
    #endif
      return registryService;
    }
  }

  services::RegistryService* Openbus::connect(
    const char* entity,
    const char* privateKeyFilename,
    const char* ACSCertificateFilename)
    throw (CORBA::SystemException, LOGIN_FAILURE, SECURITY_EXCEPTION)
  {
  #ifdef VERBOSE
    verbose->print("Openbus::connect() BEGIN");
    verbose->indent();
  #endif
    if (connectionState == DISCONNECTED) {
      try {
      #ifdef VERBOSE
        std::stringstream portMSG;
        std::stringstream entityMSG;
        std::stringstream privateKeyFilenameMSG;
        std::stringstream ACSCertificateFilenameMSG;
        verbose->print("host = " + hostBus);
        portMSG << "port = " << portBus; 
        verbose->print(portMSG.str());
        entityMSG << "entity = " << entity;
        verbose->print(entityMSG.str());
        privateKeyFilenameMSG << "privateKeyFilename = " << privateKeyFilename;
        verbose->print(privateKeyFilenameMSG.str());
        ACSCertificateFilenameMSG << "ACSCertificateFilename = " << 
          ACSCertificateFilename;
        verbose->print(ACSCertificateFilenameMSG.str());
       #endif
        if (CORBA::is_nil(iAccessControlService)) {
          createProxyToIAccessControlService();
        }

      /* Requisição de um "desafio" que somente poderá ser decifrado através
      *  da chave privada da entidade reconhecida pelo barramento.
      */
        openbusidl::OctetSeq_var octetSeq =
          iAccessControlService->getChallenge(entity);
        if (octetSeq->length() == 0) {
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          throw SECURITY_EXCEPTION(
            "O ACS não encontrou o certificado do serviço.");
        }
        unsigned char* challenge = octetSeq->get_buffer();

      /* Leitura da chave privada da entidade. */
        FILE* fp = fopen(privateKeyFilename, "r");
        if (fp == 0) {
        #ifdef VERBOSE
          stringstream filename;
          filename << "Não foi possível abrir o arquivo: " << 
            privateKeyFilename;
          verbose->print(filename.str());
        #endif
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          throw SECURITY_EXCEPTION(
            "Não foi possível abrir o arquivo que armazena a chave privada.");
        }
        EVP_PKEY* privateKey = PEM_read_PrivateKey(fp, 0, 0, 0);
        fclose(fp);
        if (privateKey == 0) {
        #ifdef VERBOSE
          verbose->print("Não foi possível obter a chave privada da entidade.");
        #endif
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          EVP_PKEY_free(privateKey);
          throw SECURITY_EXCEPTION(
            "Não foi possível obter a chave privada da entidade.");
        }

        int RSAModulusSize = EVP_PKEY_size(privateKey);

      /* Decifrando o desafio. */
        unsigned char* challengePlainText =
          (unsigned char*) malloc(RSAModulusSize);
        memset(challengePlainText, ' ', RSAModulusSize);

        RSA_private_decrypt(RSAModulusSize, challenge, challengePlainText,
          privateKey->pkey.rsa, RSA_PKCS1_PADDING);

      /* Leitura do certificado do ACS. */
        FILE* certificateFile = fopen(ACSCertificateFilename, "rb");
        if (certificateFile == 0) {
          free(challengePlainText);
        #ifdef VERBOSE
          stringstream filename;
          filename << "Não foi possível abrir o arquivo: " << 
            ACSCertificateFilename;
          verbose->print(filename.str());
        #endif
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          EVP_PKEY_free(privateKey);
          fclose(certificateFile);
          throw SECURITY_EXCEPTION(
            "Não foi possível abrir o arquivo que armazena o certificado ACS.");
        }

        EVP_PKEY_free(privateKey);

        X509* x509 = d2i_X509_fp(certificateFile, 0);
        fclose(certificateFile);
      
      /* Obtenção da chave pública do ACS. */
        EVP_PKEY* publicKey = X509_get_pubkey(x509);
        if (publicKey == 0) {
        #ifdef VERBOSE
          verbose->print("Não foi possível obter a chave pública do ACS.");
        #endif
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          free(challengePlainText);
          EVP_PKEY_free(publicKey);
          X509_free(x509);
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

        EVP_PKEY_free(publicKey);
        X509_free(x509);

      #ifdef VERBOSE
        stringstream iACSMSG;
        iACSMSG << "iAccessControlService = " << &iAccessControlService; 
        verbose->print(iACSMSG.str());
      #endif
        mutex.lock();
        if (!iAccessControlService->loginByCertificate(entity, answerOctetSeq,
          credential, lease))
        {
          free(answer);
          mutex.unlock();
          throw LOGIN_FAILURE();
        } else {
          free(answer);
        #ifdef VERBOSE
          stringstream msg;
          msg << "Associando credencial " << &credential << " ao ORB."; 
          verbose->print(msg.str());
        #endif
          connectionState = CONNECTED;
          openbus::common::ClientInterceptor::credential = credential;
          if (!timeRenewingFixe) {
            timeRenewing = (lease/2)*300;
          }
          if (!renewLeaseThread) {
            renewLeaseThread = new RenewLeaseThread();
            renewLeaseIT_Thread = IT_ThreadFactory::smf_start(
              *renewLeaseThread, 
              IT_ThreadFactory::attached, 0);
          }
          mutex.unlock();
          registryService = setRegistryService();
        #ifdef VERBOSE
          verbose->dedent("Openbus::connect() END");
        #endif
          return registryService;
        }
      } catch (const CORBA::SystemException& systemException) {
        mutex.unlock();
      #ifdef VERBOSE
        verbose->print("Throwing CORBA::SystemException...");
        verbose->dedent("Openbus::connect() END");
      #endif
        throw;
      }
    } else {
    #ifdef VERBOSE
      verbose->print("Já há uma conexão ativa.");
      verbose->dedent("Openbus::connect() END");
    #endif
      return registryService;
    }
  }

  bool Openbus::disconnect() {
  #ifdef VERBOSE
    verbose->print("Openbus::disconnect() BEGIN");
    verbose->indent();
  #endif
    mutex.lock();
    if (connectionState == CONNECTED) {
      if (iRegistryService) {
        delete iRegistryService;
      }
      if (registryService) {
        delete registryService;
      }
      bool status = iAccessControlService->logout(*credential);
      if (status) {
        openbus::common::ClientInterceptor::credential = 0;
        newState();
      } else {
        connectionState = CONNECTED;
      }
    #ifdef VERBOSE
      verbose->dedent("Openbus::disconnect() END");
    #endif
      mutex.unlock();
      return status;
    } else {
    #ifdef VERBOSE
      verbose->print("Não há conexão a ser desfeita.");
      verbose->dedent("Openbus::disconnect() END");
    #endif
      mutex.unlock();
      return false;
    }
  }

  void Openbus::run() {
    orb->run();
  }

  void Openbus::finish(bool force) {
  #ifdef VERBOSE
    verbose->print("Openbus::finish() BEGIN");
    verbose->indent();
    stringstream msg;
    msg << "Desligando orb com force = " << force; 
    verbose->print(msg.str());
  #endif
    orb->shutdown(force);
    orb = CORBA::ORB::_nil();
  #ifdef VERBOSE
    verbose->dedent("Openbus::finish() END");
  #endif
  }
}


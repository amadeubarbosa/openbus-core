/*
** openbus.cpp
*/

#include "openbus.h"

#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <sstream>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef OPENBUS_MICO
  #include <CORBA.h>
  #include <stubs/mico/scs.h>
  #include <mico/pi_impl.h>
#else
  #include <omg/orb.hh>
  #include <it_ts/thread.h>
  #include <stubs/orbix/scs.hh>
#endif

#define CHALLENGE_SIZE 36

namespace openbus {
  Logger* Openbus::logger  = 0;
  char* Openbus::debugFile = 0;
  interceptors::ORBInitializerImpl* Openbus::ini = 0;
#ifndef OPENBUS_MICO
  IT_Mutex Openbus::mutex;
#endif
  Openbus* Openbus::bus = 0;
#ifndef OPENBUS_MICO
  Openbus::RenewLeaseThread* Openbus::renewLeaseThread = 0;
#else
  #ifdef MULTITHREAD
    Openbus::RunThread* Openbus::runThread = 0;
  #endif
#endif

#ifdef OPENBUS_MICO
  #ifdef MULTITHREAD
    void Openbus::RunThread::_run(void*) {
      logger->log(INFO, "*** RunThread iniciada...");
      bus->orb->run();
      logger->log(INFO, "*** RunThread encerrada...");
    }
  #else
    Openbus::RenewLeaseCallback::RenewLeaseCallback() {
      leaseExpiredCallback = 0;
    }
  
    void Openbus::RenewLeaseCallback::setLeaseExpiredCallback(
      LeaseExpiredCallback* obj) 
    {
      leaseExpiredCallback = obj;
    }
  
    void Openbus::RenewLeaseCallback::callback(
      CORBA::Dispatcher* dispatcher, 
      Event event) 
    {
      logger->log(INFO, "Openbus::RenewLeaseCallback::callback() BEGIN");
      logger->indent();
      if (bus && bus->connectionState == CONNECTED) {
        logger->log(INFO, "Renovando credencial...");
        try {
          bool status = bus->iLeaseProvider->renewLease(*bus->credential, 
            bus->lease);
          if (!bus->timeRenewingFixe) {
            bus->timeRenewing = bus->lease*1000;
          }
          stringstream msg;
          msg << "Proximo intervalo de renovacao: " << bus->timeRenewing << "ms";
          logger->log(INFO, msg.str());
          if (!status) {
            logger->log(WARNING, "Nao foi possivel renovar a credencial!");
          /* "Desconecta" o usuario. */
            bus->localDisconnect();
            if (leaseExpiredCallback) {
              leaseExpiredCallback->expired();
            }
          } else {
            logger->log(INFO, "Credencial renovada!");
            dispatcher->tm_event(this, bus->timeRenewing);
          }
        } catch (CORBA::Exception& e) {
          logger->log(WARNING, "Nao foi possivel renovar a credencial!");
        /* "Desconecta" o usuario. ? */
          bus->localDisconnect();
          if (leaseExpiredCallback) {
            leaseExpiredCallback->expired();
          }
        }
        logger->dedent(INFO, "Openbus::RenewLeaseCallback::callback() END");
      }
    }
  #endif
#endif

  void Openbus::terminationHandlerCallback(long signalType) {
    logger->log(INFO, "Openbus::terminationHandlerCallback() BEGIN");
    logger->indent();
    try {
      if (bus->isConnected()) {
        bus->disconnect();
      }
    } catch(CORBA::Exception& e) {
      logger->log(WARNING, 
        "Não foi possível se desconectar corretamente do barramento."); 
    }
    delete bus;
    logger->dedent(INFO, "Openbus::terminationHandlerCallback() END");
  }

  void Openbus::localDisconnect() {
    if (iRegistryService) {
      delete iRegistryService;
    }
    openbus::interceptors::ClientInterceptor::credential = 0;
    if (credential) {
      delete credential;
    }
    newState();
  }

#ifndef OPENBUS_MICO
  Openbus::RenewLeaseThread::RenewLeaseThread() {
    leaseExpiredCallback = 0;
  }

  void Openbus::RenewLeaseThread::setLeaseExpiredCallback(
    LeaseExpiredCallback* obj) 
  {
    leaseExpiredCallback = obj;
  }

  void* Openbus::RenewLeaseThread::run() {
    unsigned int timeRenewing;
    logger->log(INFO, "Openbus::RenewLeaseThread::run() BEGIN");
    while (true) {
    #ifndef OPENBUS_MICO
      mutex.lock();
    #endif
      if (!bus) {
      #ifndef OPENBUS_MICO
        mutex.unlock();
      #endif
        break;
      }
      timeRenewing = bus->timeRenewing;
    #ifndef OPENBUS_MICO
      mutex.unlock();
    #endif
      IT_CurrentThread::sleep(timeRenewing);
      logger->log(INFO, "Openbus::RenewLeaseThread::run() RUN");
      logger->indent();
      stringstream msg;
      msg << "Thread: " << this;
      logger->log(INFO, msg.str());
    #ifndef OPENBUS_MICO
      mutex.lock();
    #endif
      if (bus && bus->connectionState == CONNECTED) {
        logger->log(INFO, "Renovando credencial...");
        try {
          bool status = bus->iLeaseProvider->renewLease(*bus->credential, 
            bus->lease);
          if (!bus->timeRenewingFixe) {
            bus->timeRenewing = (bus->lease/2)*300;
          }
          stringstream msg;
          msg << "Próximo intervalo de renovação: " << bus->timeRenewing << "ms";
          logger->log(INFO, msg.str());
          if (!status) {
            logger->log(WARNING, "Não foi possível renovar a credencial!");
            if (leaseExpiredCallback) {
              leaseExpiredCallback->expired();
            }
          /* "Desconecta" o usuário. */
            bus->localDisconnect();
          } else {
            logger->log(INFO, "Credencial renovada!");
          }
        } catch (CORBA::Exception& e) {
          logger->log(WARNING, "Não foi possível renovar a credencial!");
          if (leaseExpiredCallback) {
            leaseExpiredCallback->expired();
          }
        /* "Desconecta" o usuário. ? */
          bus->localDisconnect();
        }
      } else {
      #ifndef OPENBUS_MICO
        mutex.unlock();
      #endif
        break;
      }
    #ifndef OPENBUS_MICO
      mutex.unlock();
    #endif
      logger->dedent(INFO, "Openbus::RenewLeaseThread::run() SLEEP");
    }
    logger->log(WARNING, "Mecanismo de renovação de credencial *desativado*...");
    logger->dedent(INFO, "Openbus::RenewLeaseThread::run() END");
    return 0;
  }
#endif

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
      } else if (!strcmp(argv[idx], "-OpenbusDebug")) {
        idx++;
        char *debugLevelStr = argv[idx];
        if (!strcmp(debugLevelStr, "ALL")) {
          debugLevel = ALL;
        } else if (!strcmp(debugLevelStr, "ERROR")) {
          debugLevel = ERROR;
        } else if (!strcmp(debugLevelStr, "INFO")) {
          debugLevel = INFO;
        } else if (!strcmp(debugLevelStr, "WARNING")) {
          debugLevel = WARNING;
        }
      } else if (!strcmp(argv[idx], "-OpenbusDebugFile")) {
        idx++;
        debugFile = argv[idx];
      }
    }
  }

  void Openbus::createOrbPoa() {
    logger->log(INFO, "Obtendo ORB...");
    orb = CORBA::ORB_init(_argc, _argv);
    getRootPOA();
  }

  void Openbus::registerInterceptors() {
    if (!ini) {
      ini = new interceptors::ORBInitializerImpl();
      PortableInterceptor::register_orb_initializer(ini);
    }
  }

  void Openbus::newState() {
    debugLevel = OFF;
    connectionState = DISCONNECTED;
    credential = 0;
    lease = 0;
    iAccessControlService = 
      access_control_service::IAccessControlService::_nil();
    iRegistryService = 0;
    iSessionService = 0;
    iLeaseProvider = access_control_service::ILeaseProvider::_nil();
    iComponentAccessControlService = scs::core::IComponent::_nil();
  }

  void Openbus::initialize() {
    hostBus = "";
    portBus = 2089;
  #ifndef OPENBUS_MICO
    orb = CORBA::ORB::_nil();
  #else
    orb = 0;
  #endif
    poa = PortableServer::POA::_nil();
    componentBuilder = 0;
  }

 void Openbus::createProxyToIAccessControlService() {
    logger->log(INFO, "Openbus::createProxyToIAccessControlService() BEGIN");
    logger->indent();
    std::stringstream corbalocACS;
    std::stringstream corbalocLP;
    std::stringstream corbalocIC;
    corbalocACS << "corbaloc::" << hostBus << ":" << portBus << "/ACS";
    logger->log(INFO, "corbaloc ACS: " + corbalocACS.str());
    corbalocLP << "corbaloc::" << hostBus << ":" << portBus << "/LP";
    logger->log(INFO, "corbaloc LeaseProvider: " + corbalocLP.str());
    corbalocIC << "corbaloc::" << hostBus << ":" << portBus << "/IC";
    logger->log(INFO, "corbaloc IComponent: " + corbalocIC.str());
    CORBA::Object_var objACS = 
      orb->string_to_object(corbalocACS.str().c_str());
    CORBA::Object_var objLP = 
      orb->string_to_object(corbalocLP.str().c_str());
    CORBA::Object_var objIC = 
      orb->string_to_object(corbalocIC.str().c_str());
    iAccessControlService = 
      access_control_service::IAccessControlService::_narrow(objACS);
    iLeaseProvider = access_control_service::ILeaseProvider::_narrow(objLP);
    iComponentAccessControlService = scs::core::IComponent::_narrow(objIC);
    logger->dedent(INFO, "Openbus::createProxyToIAccessControlService() END");
  }

  void Openbus::setRegistryService() {
    if (!iRegistryService) {
      iRegistryService = getRegistryService(); 
    }
  }

  Openbus::Openbus() {
    newState();
    registerInterceptors();
    initialize();
  }

  Openbus::~Openbus() {
    logger->log(INFO, "Openbus::~Openbus() BEGIN");
    logger->indent();
    logger->log(INFO, "Deletando lista de métodos interceptáveis...");
    IfaceMap::iterator iter = ifaceMap.begin();
    while (iter != ifaceMap.end()) {
      MethodSet *methods = iter->second;
      ifaceMap.erase(iter++);
      methods->clear();
      delete methods;
    }
    if (componentBuilder) {
      logger->log(INFO, "Deletando objeto componentBuilder...");
      delete componentBuilder;
    }
  #ifndef OPENBUS_MICO
    if (!CORBA::is_nil(orb)) {
  #else
    if (orb) {
  #endif
      logger->log(INFO, "Desligando o orb...");
    #ifdef OPENBUS_MICO
    /*
    * Alternativa para um memory leak.
    * Referente ao Mico 2.3.11.
    */
      CORBA::Codeset::free();

  /*    PInterceptor::PI::S_initializers_.erase(
        PInterceptor::PI::S_initializers_.begin(),
        PInterceptor::PI::S_initializers_.end());
  */      
    /*
    * Alternativa para o segundo problema apresentado em OPENBUS-427.
    * Referente ao Mico 2.3.11.
    */
  /*  PInterceptor::PI::S_client_req_int_.erase(
        PInterceptor::PI::S_client_req_int_.begin(),
        PInterceptor::PI::S_client_req_int_.end());
      PInterceptor::PI::S_server_req_int_.erase(
        PInterceptor::PI::S_server_req_int_.begin(),
        PInterceptor::PI::S_server_req_int_.end());
  */      
      logger->log(INFO, "Removendo callback de renovação de credencial...");
      orb->dispatcher()->remove(&renewLeaseCallback, CORBA::Dispatcher::Timer);
      if (ini->_info) {
        delete ini->_info;
      }
    #endif
      logger->log(INFO, "Executando orb->shutdown(1) ...");
      orb->shutdown(1);
      logger->log(INFO, "Executando orb->destroy() ...");
      orb->destroy();
    }
  #ifndef OPENBUS_MICO
    mutex.lock();
  #endif
    bus = 0;
  #ifndef OPENBUS_MICO
    mutex.unlock();
    if (renewLeaseThread) {
      logger->log(INFO, "Esperando término de execução da Thread de renovação...");
      renewLeaseIT_Thread.join();
      logger->log(INFO, "Deletando objeto renewLeaseThread...");
      delete renewLeaseThread;
      renewLeaseThread = 0;
      if (credential) {
        delete credential;
      }
    }
  #endif
    logger->dedent(INFO, "Openbus::~Openbus() END");
  }

  Openbus* Openbus::getInstance() {
    logger = Logger::getInstance();
    if (!bus) {
    #ifndef OPENBUS_MICO
      mutex.lock();
    #endif
      bus = new Openbus();
    #ifndef OPENBUS_MICO
      mutex.unlock();
    #endif
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
    logger->setOutput(debugFile);
    logger->setLevel(debugLevel);
    logger->log(INFO, "Openbus::init(int argc, char** argv) BEGIN");
    logger->indent();
    createOrbPoa();
    if (!componentBuilder) {
      componentBuilder = new scs::core::ComponentBuilder(orb, poa);
    }
    logger->dedent(INFO, "Openbus::init() END");
  }

  void Openbus::init(
    int argc,
    char** argv,
    char* host,
    unsigned short port)
  {
    logger->log(INFO, "Openbus::init(int argc, char** argv, char* host, \
      unsigned short port) BEGIN");
    logger->indent();
    init(argc, argv);
    hostBus = host;
    portBus = port;
    logger->dedent(INFO, "Openbus::init(int argc, char** argv, char* host, \
      unsigned short port) END");
  }

  bool Openbus::isConnected() {
    logger->log(INFO, "Openbus::isConnected() BEGIN");
    logger->indent();
    if (connectionState == CONNECTED) {
      logger->log(INFO, "Está conectado.");
      logger->dedent(INFO, "Openbus::isConnected() END");
      return true;
    }
    logger->log(INFO, "NÃO está conectado.");
    logger->dedent(INFO, "Openbus::isConnected() END");
    return false;
  }

  CORBA::ORB* Openbus::getORB() {
    return orb;
  }

  PortableServer::POA* Openbus::getRootPOA() {
    logger->log(INFO, "Openbus::getRootPOA() BEGIN");
    logger->indent();
  #ifdef OPENBUS_MICO
    /*
    * Alternativa para o segundo problema apresentado em OPENBUS-426.
    * Referente ao Mico 2.3.11.
    */
    if (PortableServer::_the_poa_current) {
      delete PortableServer::_the_poa_current;
    }
  #endif

    if (CORBA::is_nil(poa)) {
      logger->log(INFO, "Obtendo POA...");
      CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
      poa = PortableServer::POA::_narrow(poa_obj);
      poa_manager = poa->the_POAManager();
      poa_manager->activate();
    }
    logger->dedent(INFO, "Openbus::getRootPOA() END");
    return poa;
  }

  scs::core::ComponentBuilder* Openbus::getComponentBuilder() {
    return componentBuilder;
  }

  access_control_service::Credential_var Openbus::getInterceptedCredential() {
    return ini->getServerInterceptor()->getCredential();
  }

  access_control_service::IAccessControlService* Openbus::getAccessControlService() {
    return iAccessControlService;
  }

  registry_service::IRegistryService* Openbus::getRegistryService() {
    logger->log(INFO, "Openbus::getRegistryService() BEGIN");
    logger->indent();
    scs::core::IComponent_var iComponentRegistryService;
    if ((scs::core::IComponent*) iComponentAccessControlService) {
      CORBA::Object_var objRecep = 
        iComponentAccessControlService->getFacetByName("IReceptacles");
      scs::core::IReceptacles_var recep = 
        scs::core::IReceptacles::_narrow(objRecep);
      try {
        scs::core::ConnectionDescriptions_var conns =
          recep->getConnections("RegistryServiceReceptacle");
        if (conns->length() > 0) {
          cout << conns->length() << endl;
          logger->log(INFO, "Adquirindo RegistryService...");
          CORBA::Object_var objref = conns[(CORBA::ULong) 0].objref;
          iComponentRegistryService = scs::core::IComponent::_narrow(objref);
          objref = iComponentRegistryService->getFacetByName("IRegistryService");
          iRegistryService = registry_service::IRegistryService::_narrow(objref);
        }
      } catch (scs::core::InvalidName& e) {
        logger->log(ERROR, "Não foi possível obter o serviço de registro.");
        // TODO: necessário fazer um throw?
      }
    }
    logger->dedent(INFO, "Openbus::getRegistryService() END");
    return iRegistryService;
  } 

  ISessionService* Openbus::getSessionService() 
    throw(NO_CONNECTED, NO_SESSION_SERVICE)
  {
    if (connectionState != CONNECTED) {
      throw NO_CONNECTED();
    } else {
      if (CORBA::is_nil(iSessionService)) {
        try {
          registry_service::FacetList_var facetList = \
            new registry_service::FacetList();
          facetList->length(1);
          facetList[(CORBA::ULong) 0] = "ISessionService";
          registry_service::ServiceOfferList_var serviceOfferList = \
            iRegistryService->find(facetList);
          registry_service::ServiceOffer serviceOffer = serviceOfferList[(CORBA::ULong) 0];
          scs::core::IComponent* component = serviceOffer.member;
          CORBA::Object* obj = \
            component->getFacet("IDL:tecgraf/openbus/session_service/v1_05/ISessionService:1.0");
          iSessionService = ISessionService::_narrow(obj);
        } catch (CORBA::Exception& e) {
          throw NO_SESSION_SERVICE();
        }
      }
    }
    return iSessionService;
  }

  access_control_service::Credential* Openbus::getCredential() {
    return credential;
  }

  void Openbus::setThreadCredential(
    access_control_service::Credential* credential) 
  {
    this->credential = credential;
    openbus::interceptors::ClientInterceptor::credential = credential;
  }

  void Openbus::setLeaseExpiredCallback(
    LeaseExpiredCallback* leaseExpiredCallback) 
  {
  #ifdef OPENBUS_MICO
    renewLeaseCallback.setLeaseExpiredCallback(leaseExpiredCallback);
  #else
    if (renewLeaseThread) {
      renewLeaseThread->setLeaseExpiredCallback(leaseExpiredCallback);
    }
  #endif
  }

  void Openbus::removeLeaseExpiredCallback()
  {
  #ifdef OPENBUS_MICO
    renewLeaseCallback.setLeaseExpiredCallback(0);
  #else
    if (renewLeaseThread) {
      renewLeaseThread->setLeaseExpiredCallback(0);
    }
  #endif
  }

  registry_service::IRegistryService* Openbus::connect(
    const char* user,
    const char* password)
    throw (CORBA::SystemException, LOGIN_FAILURE)
  {
    logger->log(INFO, "Openbus::connect() BEGIN");
    logger->indent();
    if (connectionState == DISCONNECTED) {
      try {
        std::stringstream portMSG;
        std::stringstream userMSG;
        std::stringstream passwordMSG;
        std::stringstream orbMSG;
        logger->log(INFO, "host = " + hostBus);
        portMSG << "port = " << portBus; 
        logger->log(INFO, portMSG.str());
        userMSG << "username = " << user;
        logger->log(INFO, userMSG.str());
        passwordMSG<< "password = " << password;
        logger->log(INFO, passwordMSG.str());
        orbMSG<< "orb = " << &orb;
        logger->log(INFO, orbMSG.str());
        if (CORBA::is_nil(iAccessControlService)) {
          createProxyToIAccessControlService();
        }

        stringstream iACSMSG;
        iACSMSG << "iAccessControlService = " << &iAccessControlService; 
        logger->log(INFO, iACSMSG.str());
      #ifndef OPENBUS_MICO
        mutex.lock();
      #endif
        if (!iAccessControlService->loginByPassword(user, password, credential,
          lease))
        {
        #ifndef OPENBUS_MICO
          mutex.unlock();
        #endif
          logger->log(ERROR, "Throwing LOGIN_FAILURE...");
          logger->dedent(INFO, "Openbus::connect() END");
          throw LOGIN_FAILURE();
        } else {

          stringstream msg;
          msg << "Associando credencial " << credential << " ao ORB.";
          logger->log(INFO, msg.str());
          connectionState = CONNECTED;
          openbus::interceptors::ClientInterceptor::credential = credential;
          if (!timeRenewingFixe) {
            timeRenewing = (lease/2)*300;
          }
          setRegistryService();
        #ifdef OPENBUS_MICO
          orb->dispatcher()->tm_event(&renewLeaseCallback, 
            timeRenewing);
        #else
          if (!renewLeaseThread) {
            renewLeaseThread = new RenewLeaseThread();
            renewLeaseIT_Thread = IT_ThreadFactory::smf_start(
              *renewLeaseThread, 
              IT_ThreadFactory::attached, 0);
          }
          mutex.unlock();
        #endif
          logger->dedent(INFO, "Openbus::connect() END");
          return iRegistryService;

        }

      } catch (const CORBA::SystemException& systemException) {
      #ifndef OPENBUS_MICO
        mutex.unlock();
      #endif
        logger->log(ERROR, "Throwing CORBA::SystemException...");
        logger->dedent(INFO, "Openbus::connect() END");
        throw;
      }
    } else {
      logger->log(INFO, "Já há uma conexão ativa.");
      logger->dedent(INFO, "Openbus::connect() END");
      return iRegistryService;
    }
  }

  registry_service::IRegistryService* Openbus::connect(
    const char* entity,
    const char* privateKeyFilename,
    const char* ACSCertificateFilename)
    throw (CORBA::SystemException, LOGIN_FAILURE, SECURITY_EXCEPTION)
  {
    logger->log(INFO, "Openbus::connect() BEGIN");
    logger->indent();
    if (connectionState == DISCONNECTED) {
      try {
        std::stringstream portMSG;
        std::stringstream entityMSG;
        std::stringstream privateKeyFilenameMSG;
        std::stringstream ACSCertificateFilenameMSG;
        logger->log(INFO, "host = " + hostBus);
        portMSG << "port = " << portBus; 
        logger->log(INFO, portMSG.str());
        entityMSG << "entity = " << entity;
        logger->log(INFO, entityMSG.str());
        privateKeyFilenameMSG << "privateKeyFilename = " << privateKeyFilename;
        logger->log(INFO, privateKeyFilenameMSG.str());
        ACSCertificateFilenameMSG << "ACSCertificateFilename = " << 
          ACSCertificateFilename;
        logger->log(INFO, ACSCertificateFilenameMSG.str());
        if (CORBA::is_nil(iAccessControlService)) {
          createProxyToIAccessControlService();
        }

      /* Requisição de um "desafio" que somente poderá ser decifrado através
      *  da chave privada da entidade reconhecida pelo barramento.
      */
        OctetSeq_var octetSeq =
          iAccessControlService->getChallenge(entity);
        if (octetSeq->length() == 0) {
          logger->log(ERROR, "Throwing SECURITY_EXCEPTION...");
          logger->dedent(INFO, "Openbus::connect() END");
          throw SECURITY_EXCEPTION(
            "O ACS não encontrou o certificado do serviço.");
        }
        unsigned char* challenge = octetSeq->get_buffer();

      /* Leitura da chave privada da entidade. */
        FILE* fp = fopen(privateKeyFilename, "r");
        if (fp == 0) {
          stringstream filename;
          filename << "Não foi possível abrir o arquivo: " << 
            privateKeyFilename;
          logger->log(INFO, filename.str());
          logger->log(ERROR, "Throwing SECURITY_EXCEPTION...");
          logger->dedent(INFO, "Openbus::connect() END");
          throw SECURITY_EXCEPTION(
            "Não foi possível abrir o arquivo que armazena a chave privada.");
        }
        EVP_PKEY* privateKey = PEM_read_PrivateKey(fp, 0, 0, 0);
        fclose(fp);
        if (privateKey == 0) {
          logger->log(WARNING, "Não foi possível obter a chave privada da entidade.");
          logger->log(ERROR, "Throwing SECURITY_EXCEPTION...");
          logger->dedent(INFO, "Openbus::connect() END");
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
          stringstream filename;
          filename << "Não foi possível abrir o arquivo: " << 
            ACSCertificateFilename;
          logger->log(WARNING, filename.str());
          logger->log(ERROR, "Throwing SECURITY_EXCEPTION...");
          logger->dedent(INFO, "Openbus::connect() END");
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
          logger->log(WARNING, "Não foi possível obter a chave pública do ACS.");
          logger->log(ERROR, "Throwing SECURITY_EXCEPTION...");
          logger->dedent(INFO, "Openbus::connect() END");
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

        OctetSeq_var answerOctetSeq = new OctetSeq(
          (CORBA::ULong) RSAModulusSize, (CORBA::ULong) RSAModulusSize,
          (CORBA::Octet*)answer, 0);

        EVP_PKEY_free(publicKey);
        X509_free(x509);

        stringstream iACSMSG;
        iACSMSG << "iAccessControlService = " << &iAccessControlService; 
        logger->log(INFO, iACSMSG.str());
      #ifndef OPENBUS_MICO
        mutex.lock();
      #endif
        if (!iAccessControlService->loginByCertificate(entity, answerOctetSeq,
          credential, lease))
        {
          free(answer);
        #ifndef OPENBUS_MICO
          mutex.unlock();
        #endif
          throw LOGIN_FAILURE();
        } else {
          free(answer);
          stringstream msg;
          msg << "Associando credencial " << credential << " ao ORB."; 
          logger->log(INFO, msg.str());
          connectionState = CONNECTED;
          openbus::interceptors::ClientInterceptor::credential = credential;
          if (!timeRenewingFixe) {
            timeRenewing = (lease/2)*300;
          }
          setRegistryService();
        #ifdef OPENBUS_MICO
          orb->dispatcher()->tm_event(&renewLeaseCallback, 
            timeRenewing);
        #else
          if (!renewLeaseThread) {
            renewLeaseThread = new RenewLeaseThread();
            renewLeaseIT_Thread = IT_ThreadFactory::smf_start(
              *renewLeaseThread, 
              IT_ThreadFactory::attached, 0);
          }
          mutex.unlock();
        #endif
          logger->dedent(INFO, "Openbus::connect() END");
          return iRegistryService;
        }
      } catch (const CORBA::SystemException& systemException) {
      #ifndef OPENBUS_MICO
        mutex.unlock();
      #endif
        logger->log(ERROR, "Throwing CORBA::SystemException...");
        logger->dedent(INFO, "Openbus::connect() END");
        throw;
      }
    } else {
      logger->log(INFO, "Já há uma conexão ativa.");
      logger->dedent(INFO, "Openbus::connect() END");
      return iRegistryService;
    }
  }

  bool Openbus::disconnect() {
    logger->log(INFO, "Openbus::disconnect() BEGIN");
    logger->indent();
  #ifndef OPENBUS_MICO
    mutex.lock();
  #endif
    if (connectionState == CONNECTED) {
    #ifdef OPENBUS_MICO
      orb->dispatcher()->remove(&renewLeaseCallback, CORBA::Dispatcher::Timer);
    #endif
      if (iRegistryService) {
        delete iRegistryService;
      }
      bool status = iAccessControlService->logout(*credential);
      if (status) {
        openbus::interceptors::ClientInterceptor::credential = 0;
        if (credential) {
          delete credential;
        }
        newState();
      } else {
        connectionState = CONNECTED;
      }
      logger->dedent(INFO, "Openbus::disconnect() END");
    #ifndef OPENBUS_MICO
      mutex.unlock();
    #endif
      return status;
    } else {
      logger->log(INFO, "Não há conexão a ser desfeita.");
      logger->dedent(INFO, "Openbus::disconnect() END");
    #ifndef OPENBUS_MICO
      mutex.unlock();
    #endif
      return false;
    }
  }

  void Openbus::run() {
    orb->run();
  }

  void Openbus::finish(bool force) {
    logger->log(INFO, "Openbus::finish() BEGIN");
    logger->indent();
    stringstream msg;
    msg << "Desligando orb com force = " << force; 
    logger->log(INFO, msg.str());
    orb->shutdown(force);
  #ifndef OPENBUS_MICO
    orb = CORBA::ORB::_nil();
  #else
    orb = 0;
  #endif
    logger->dedent(INFO, "Openbus::finish() END");
  }

  void Openbus::setInterceptable(string iface, string method,
    bool interceptable)
  {
    MethodSet *methods;
    IfaceMap::iterator iter;
    /* Guarda apenas os métodos que não são interceptados */
    if (interceptable) {
      iter = ifaceMap.find(iface);
      if (iter != ifaceMap.end()) {
        methods = iter->second;
        methods->erase(method);
        if (methods->size() == 0) {
          ifaceMap.erase(iter);
          delete methods;
        }
      }
    }
    else {
      iter = ifaceMap.find(iface);
      if (iter == ifaceMap.end()) {
        methods = new MethodSet();
        ifaceMap[iface] = methods;
      }
      else
        methods = iter->second;
      methods->insert(method);
    }
  }

  bool Openbus::isInterceptable(string iface, string method)
  {
    IfaceMap::iterator iter = ifaceMap.find(iface);
    if (iter != ifaceMap.end()) {
      MethodSet *methods = iter->second;
      MethodSet::iterator method_iter = methods->find(method);
      return (method_iter == methods->end());
    }
    return true;
  }

}


/*
** openbus.cpp
*/

#include "openbus.h"

#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <CORBA.h>
#include <mico/pi_impl.h>
#include <sstream>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define CHALLENGE_SIZE 36

namespace openbus {
#ifdef VERBOSE
  Verbose* Openbus::verbose = 0;
#endif

#ifdef MULTITHREAD
  Openbus::RunThread* Openbus::runThread = 0;
#endif

  interceptors::ORBInitializerImpl* Openbus::ini = 0;
  Openbus* Openbus::bus = 0;

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
  #ifdef VERBOSE
    verbose->print("Openbus::RenewLeaseCallback::callback() BEGIN");
    verbose->indent();
  #endif
    if (bus && bus->connectionState == CONNECTED) {
    #ifdef VERBOSE
      verbose->print("Renovando credencial...");
    #endif
      try {
        bool status = bus->iLeaseProvider->renewLease(*bus->credential, 
          bus->lease);
        if (!bus->timeRenewingFixe) {
          bus->timeRenewing = bus->lease*1000;
        }
      #ifdef VERBOSE
        stringstream msg;
        msg << "Proximo intervalo de renovacao: " << bus->timeRenewing << "ms";
        verbose->print(msg.str());
      #endif
        if (!status) {
        #ifdef VERBOSE
          verbose->print("Nao foi possivel renovar a credencial!");
        #endif
        /* "Desconecta" o usuario. */
          bus->localDisconnect();
          if (leaseExpiredCallback) {
            leaseExpiredCallback->expired();
          }
        } else {
        #ifdef VERBOSE
          verbose->print("Credencial renovada!");
        #endif
          dispatcher->tm_event(this, bus->timeRenewing);
        }
      } catch (CORBA::Exception& e) {
      #ifdef VERBOSE
        verbose->print("Nao foi possivel renovar a credencial!");
      #endif
      /* "Desconecta" o usuario. ? */
        bus->localDisconnect();
        if (leaseExpiredCallback) {
          leaseExpiredCallback->expired();
        }
      }
    #ifdef VERBOSE
      verbose->dedent("Openbus::RenewLeaseCallback::callback() END");
    #endif
    }
  }

#ifdef MULTITHREAD
  void Openbus::RunThread::_run(void*) {
  #ifdef VERBOSE
    verbose->print("*** RunThread iniciada...");
  #endif
    bus->orb->run();
  #ifdef VERBOSE
    verbose->print("*** RunThread encerrada...");
  #endif
  }
#endif

  void Openbus::terminationHandlerCallback(long signalType) {
  #ifdef VERBOSE
    verbose->print("Openbus::terminationHandlerCallback() BEGIN");
    verbose->indent();
  #endif
    try {
      if (bus->isConnected()) {
        bus->disconnect();
      }
    } catch(CORBA::Exception& e) {
    #ifdef VERBOSE
      verbose->print(
        "Nao foi possivel se desconectar corretamente do barramento."); 
    #endif
    }
    delete bus;
  #ifdef VERBOSE
    verbose->dedent("Openbus::terminationHandlerCallback() END");
  #endif
  }

  void Openbus::localDisconnect() {
    orb->dispatcher()->remove(&renewLeaseCallback, CORBA::Dispatcher::Timer);
    if (iRegistryService) {
      delete iRegistryService;
    }
    openbus::interceptors::ClientInterceptor::credential = 0;
    if (credential) {
      delete credential;
    }
    newState();
  }

  void Openbus::commandLineParse() {
    timeRenewingFixe = false;
    for (short idx = 1; idx < _argc; idx++) {
      if (!strcmp(_argv[idx], "-OpenbusHost")) {
        idx++;
        hostBus = _argv[idx];
      } else if (!strcmp(_argv[idx], "-OpenbusPort")) {
        idx++;
        portBus = atoi(_argv[idx]);
      } else if (!strcmp(_argv[idx], "-TimeRenewing")) {
        timeRenewing = (unsigned int) atoi(_argv[++idx]);
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
      ini = new interceptors::ORBInitializerImpl();
      PortableInterceptor::register_orb_initializer(ini);
    }
  }

  void Openbus::newState() {
    connectionState = DISCONNECTED;
    credential = 0;
    lease = 0;
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

  void Openbus::setRegistryService() {
    if (!iRegistryService) {
      iRegistryService = iAccessControlService->getRegistryService(); 
    }
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
    verbose->print("Deletando lista de m�todos intercept�veis...");
  #endif
    IfaceMap::iterator iter = ifaceMap.begin();
    while (iter != ifaceMap.end()) {
      MethodSet *methods = iter->second;
      ifaceMap.erase(iter++);
      methods->clear();
      delete methods;
    }
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
    /*
    * Alternativa para um memory leak.
    * Referente ao Mico 2.3.11.
    */
      CORBA::Codeset::free();

    /*
    * Alternativa para o segundo problema apresentado em OPENBUS-427.
    * Referente ao Mico 2.3.11.
    */
      PInterceptor::PI::S_client_req_int_.erase(
        PInterceptor::PI::S_client_req_int_.begin(),
        PInterceptor::PI::S_client_req_int_.end());
      PInterceptor::PI::S_server_req_int_.erase(
        PInterceptor::PI::S_server_req_int_.begin(),
        PInterceptor::PI::S_server_req_int_.end());

      orb->shutdown(1);
      orb->destroy();
      if (credential) {
        delete credential;
      }
    #ifdef MULTITHREAD
      if (runThread) {
      #ifdef VERBOSE
        verbose->print("Esperando termino de execucaoo da runThread...");
      #endif
        runThread->wait();
      #ifdef VERBOSE
        verbose->print("Deletando objeto runThread...");
      #endif
        delete runThread;
        runThread = 0;
      }
    #endif
    }
    bus = 0;
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
      scs::core::IReceptaclesImpl::verbose = verbose;
    }
    verbose->print("Openbus::getInstance() BEGIN");
    verbose->indent();
  #endif
    if (!bus) {
    #ifdef VERBOSE
      verbose->print("Criando novo objeto...");
    #endif
      bus = new Openbus();
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
    commandLineParse();
    createOrbPoa();
    if (!componentBuilder) {
      componentBuilder = new scs::core::ComponentBuilder(orb, poa);
    }
  #ifdef MULTITHREAD
    if (!runThread) {
      runThread = new RunThread();
      runThread->start();
    }
  #endif

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
      verbose->print("Esta conectado.");
      verbose->dedent("Openbus::isConnected() END");
    #endif
      return true;
    }
  #ifdef VERBOSE
    verbose->print("NaO esta conectado.");
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
    /*
    * Alternativa para o segundo problema apresentado em OPENBUS-426.
    * Referente ao Mico 2.3.11.
    */
    if (PortableServer::_the_poa_current) {
      delete PortableServer::_the_poa_current;
    }

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

  openbusidl::rs::IRegistryService* Openbus::getRegistryService() {
    return iRegistryService;
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
          facetList[(CORBA::ULong) 0] = "ISessionService";
          openbusidl::rs::ServiceOfferList_var serviceOfferList = \
            iRegistryService->find(facetList);
          openbusidl::rs::ServiceOffer serviceOffer = 
            serviceOfferList[(CORBA::ULong) 0];
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
    openbus::interceptors::ClientInterceptor::credential = credential;
  }

  void Openbus::addLeaseExpiredCallback(
    LeaseExpiredCallback* leaseExpiredCallback) 
  {
    renewLeaseCallback.setLeaseExpiredCallback(leaseExpiredCallback);
  }

  void Openbus::removeLeaseExpiredCallback()
  {
    renewLeaseCallback.setLeaseExpiredCallback(0);
  }

  openbusidl::rs::IRegistryService* Openbus::connect(
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
        if (!iAccessControlService->loginByPassword(user, password, credential,
          lease))
        {
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
          openbus::interceptors::ClientInterceptor::credential = credential;
          if (!timeRenewingFixe) {
            timeRenewing = lease*1000;
          }
          setRegistryService();
          orb->dispatcher()->tm_event(&renewLeaseCallback, 
            timeRenewing);
        #ifdef VERBOSE
          verbose->dedent("Openbus::connect() END");
        #endif
          return iRegistryService;

        }

      } catch (const CORBA::SystemException& systemException) {
      #ifdef VERBOSE
        verbose->print("Throwing CORBA::SystemException...");
        verbose->dedent("Openbus::connect() END");
      #endif
        throw;
      }
    } else {
    #ifdef VERBOSE
      verbose->print("Ja ha uma conexao ativa.");
      verbose->dedent("Openbus::connect() END");
    #endif
      return iRegistryService;
    }
  }

  openbusidl::rs::IRegistryService* Openbus::connect(
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

      /* Requisicao de um "desafio" que somente podera ser decifrado atraves
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
            "O ACS nao encontrou o certificado do servico.");
        }
        unsigned char* challenge = octetSeq->get_buffer();

      /* Leitura da chave privada da entidade. */
        FILE* fp = fopen(privateKeyFilename, "r");
        if (fp == 0) {
        #ifdef VERBOSE
          stringstream filename;
          filename << "Nao foi possivel abrir o arquivo: " << 
            privateKeyFilename;
          verbose->print(filename.str());
        #endif
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          throw SECURITY_EXCEPTION(
            "Nao foi possivel abrir o arquivo que armazena a chave privada.");
        }
        EVP_PKEY* privateKey = PEM_read_PrivateKey(fp, 0, 0, 0);
        fclose(fp);
        if (privateKey == 0) {
        #ifdef VERBOSE
          verbose->print("Nao foi possivel obter a chave privada da entidade.");
        #endif
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          EVP_PKEY_free(privateKey);
          throw SECURITY_EXCEPTION(
            "Nao foi possivel obter a chave privada da entidade.");
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
          filename << "Nao foi possivel abrir o arquivo: " << 
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
            "Nao foi possivel abrir o arquivo que armazena o certificado ACS.");
        }

        EVP_PKEY_free(privateKey);

        X509* x509 = d2i_X509_fp(certificateFile, 0);
        fclose(certificateFile);
      
      /* Obtencao da chave publica do ACS. */
        EVP_PKEY* publicKey = X509_get_pubkey(x509);
        if (publicKey == 0) {
        #ifdef VERBOSE
          verbose->print("Nao foi possivel obter a chave publica do ACS.");
        #endif
        #ifdef VERBOSE
          verbose->print("Throwing SECURITY_EXCEPTION...");
          verbose->dedent("Openbus::connect() END");
        #endif
          free(challengePlainText);
          EVP_PKEY_free(publicKey);
          X509_free(x509);
          throw SECURITY_EXCEPTION(
            "Nao foi possivel obter a chave publica do ACS.");
        }

      /* Reposta ao desafio, ou seja, cifra do desafio utilizando a chave
      *  publica do ACS.
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
        if (!iAccessControlService->loginByCertificate(entity, answerOctetSeq,
          credential, lease))
        {
          free(answer);
          throw LOGIN_FAILURE();
        } else {
          free(answer);
        #ifdef VERBOSE
          stringstream msg;
          msg << "Associando credencial " << credential << " ao ORB."; 
          verbose->print(msg.str());
        #endif
          connectionState = CONNECTED;
          openbus::interceptors::ClientInterceptor::credential = credential;
          if (!timeRenewingFixe) {
            timeRenewing = lease*1000;
          }
          setRegistryService();
          orb->dispatcher()->tm_event(&renewLeaseCallback, 
            timeRenewing);
        #ifdef VERBOSE
          verbose->dedent("Openbus::connect() END");
        #endif
          return iRegistryService;
        }
      } catch (const CORBA::SystemException& systemException) {
      #ifdef VERBOSE
        verbose->print("Throwing CORBA::SystemException...");
        verbose->dedent("Openbus::connect() END");
      #endif
        throw;
      }
    } else {
    #ifdef VERBOSE
      verbose->print("Ja ha uma conexao ativa.");
      verbose->dedent("Openbus::connect() END");
    #endif
      return iRegistryService;
    }
  }

  bool Openbus::disconnect() {
  #ifdef VERBOSE
    verbose->print("Openbus::disconnect() BEGIN");
    verbose->indent();
  #endif
    if (connectionState == CONNECTED) {
      orb->dispatcher()->remove(&renewLeaseCallback, CORBA::Dispatcher::Timer);
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
    #ifdef VERBOSE
      verbose->dedent("Openbus::disconnect() END");
    #endif
      return status;
    } else {
    #ifdef VERBOSE
      verbose->print("Nao ha conexao a ser desfeita.");
      verbose->dedent("Openbus::disconnect() END");
    #endif
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

  void Openbus::setInterceptable(string iface, string method,
    bool interceptable)
  {
    MethodSet *methods;
    IfaceMap::iterator iter;
    /* Guarda apenas os m�todos que n�o s�o interceptados */
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


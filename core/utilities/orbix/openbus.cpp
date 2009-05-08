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
  std::set<Openbus*> Openbus::busSet;

  void Openbus::terminationHandlerCallback(long signalType) {
  #ifdef VERBOSE
    cout << "[Openbus::terminationHandlerCallback() BEGIN]" << endl;
  #endif
    std::set<Openbus*>::iterator it;
    for (it = busSet.begin(); it != busSet.end(); it++) {
      Openbus* bus = *it;
      bus->disconnect();
      if (!CORBA::is_nil(bus->orb)) {
        bus->orb->shutdown(0);
      }
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
        bus->accessControlService->renewLease(*bus->credential, bus->lease);
      }
      bus->mutex->unlock();
    }
  #ifdef VERBOSE
    cout << "[Mecanismo de renova��o de credencial *desativado*...]" << endl;
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
    if (!ini) {
      cout << "Registrando interceptadores ..." << endl;
      registerInterceptors();
    }
    initialize();
    commandLineParse(_argc, _argv);
    busSet.insert(this);
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
    initialize();
    commandLineParse(_argc, _argv);
    hostBus = (char*) malloc(sizeof(char) * strlen(host) + 1);
    hostBus = (char*) memcpy(hostBus, host, strlen(host) + 1);
    portBus = port;
    busSet.insert(this);
  }

  Openbus::~Openbus() {
    busSet.erase(this);
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

  CORBA::ORB* Openbus::getORB() {
    return orb;
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
          accessControlService = new openbus::services::AccessControlService(
            hostBus, portBus, orb);
        }
        IAccessControlService* iAccessControlService =
          accessControlService->getStub();
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

  services::RegistryService* Openbus::connect(
    const char* entity,
    const char* privateKeyFilename,
    const char* ACSCertificateFilename)
    throw (COMMUNICATION_FAILURE, LOGIN_FAILURE, SECURITY_EXCEPTION)
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
        if (accessControlService == 0) {
          accessControlService = new openbus::services::AccessControlService(
            hostBus, portBus, orb);
        }

        IAccessControlService* iAccessControlService =
          accessControlService->getStub();

      /* Requisi��o de um "desafio" que somente poder� ser decifrado atrav�s
      *  da chave privada da entidade reconhecida pelo barramento.
      */
        openbusidl::OctetSeq* octetSeq =
          iAccessControlService->getChallenge(entity);
        unsigned char* challange = octetSeq->get_buffer();

      /* Leitura da chave privada da entidade. */
        FILE* fp = fopen(privateKeyFilename, "r");
        if (fp == 0) {
        #ifdef VERBOSE
          cout << "\tN�o foi poss�vel abrir o arquivo: " << privateKeyFilename
            << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "N�o foi poss�vel abrir o arquivo que armazena a chave privada.");
        }
        EVP_PKEY* privateKey = PEM_read_PrivateKey(fp, 0, 0, 0);
        if (privateKey == 0) {
        #ifdef VERBOSE
          cout << "\tN�o foi poss�vel obter a chave privada da entidade."
            << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "N�o foi poss�vel obter a chave privada da entidade.");
        }

        int RSAModulusSize = EVP_PKEY_size(privateKey);

      /* Decifrando o desafio. */
        unsigned char* challengePlainText =
          (unsigned char*) malloc(RSAModulusSize);
        RSA_private_decrypt(RSAModulusSize, challange, challengePlainText,
          privateKey->pkey.rsa, RSA_PKCS1_PADDING);

      /* Leitura do certificado do ACS. */
        FILE* certificateFile = fopen(ACSCertificateFilename, "rb");
        if (certificateFile == 0) {
          free(challengePlainText);
        #ifdef VERBOSE
          cout << "\tN�o foi poss�vel abrir o arquivo: " <<
            ACSCertificateFilename << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "N�o foi poss�vel abrir o arquivo que armazena o certificado ACS.");
        }
        X509* x509 = d2i_X509_fp(certificateFile, 0);

      /* Obten��o da chave p�blica do ACS. */
        EVP_PKEY* publicKey = X509_get_pubkey(x509);
        if (publicKey == 0) {
        #ifdef VERBOSE
          cout << "\tN�o foi poss�vel obter a chave p�blica do ACS." << endl;
        #endif
          throw SECURITY_EXCEPTION(
            "N�o foi poss�vel obter a chave p�blica do ACS.");
        }

      /* Reposta ao desafio, ou seja, cifra do desafio utilizando a chave
      *  p�blica do ACS.
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
    cout << "[Openbus::connect() END]" << endl;
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
      cout << "[N�o h� conex�o a ser desfeita.]" << endl;
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

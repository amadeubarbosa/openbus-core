/**
* \mainpage API - Openbus Orbix C++
* \file openbus.h
*/

#ifndef OPENBUS_H_
#define OPENBUS_H_

#include "services/AccessControlService.h"
#include "services/RegistryService.h"

#include "openbus/common/ORBInitializerImpl.h"
#include <ComponentBuilderOrbix.h>

#include <omg/orb.hh>
#include <it_ts/thread.h>
#include <it_ts/mutex.h>

#include <stdexcept>
#include <set>

using namespace openbusidl::acs;
IT_USING_NAMESPACE_STD

/**
* \brief Stubs dos serviços básicos.
*/
namespace openbusidl {

/**
* \brief Stub do serviço de acesso.
*/
  namespace acs {

  /**
  * \class Credential
  * \brief Credencial
  */

  }
}

/**
* \brief openbus
*/
namespace openbus {

/**
* \brief Falha no processo de login, ou seja, o par nome de usuário e senha não
* foi validado.
*/
  class LOGIN_FAILURE : public runtime_error {
    public:
      LOGIN_FAILURE(const string& msg = "") : runtime_error(msg) {}
  };

/**
* \brief Falha na manipulação da chave privada da entidade ou do certificado 
* ACS.
*/
  class SECURITY_EXCEPTION : public runtime_error {
    public:
      SECURITY_EXCEPTION(const string& msg = "") : runtime_error(msg) {}
  };

  typedef openbusidl::acs::Credential_var Credential_var;

  /**
  * \brief Representa um barramento.
  */
  class Openbus {
    private:

    /**
    * A instância única do barramento.
    */
      static Openbus* bus;

    /**
    * Parâmetro argc da linha de comando. 
    */
      int _argc;

    /**
    * Parâmetro argv da linha de comando. 
    */
      char** _argv;

    /**
    * Inicializador do ORB. 
    */
      static common::ORBInitializerImpl* ini;

    /**
    * ORB 
    */
      CORBA::ORB* orb;

    /**
    * POA 
    */
      PortableServer::POA* poa;

    /**
    * Fábrica de componentes SCS. 
    */
      scs::core::ComponentBuilder* componentBuilder;

    /**
    * Gerenciador do POA. 
    */
      PortableServer::POAManager_var poa_manager;

    /**
    * Serviço de acesso. 
    */
      services::AccessControlService* accessControlService;

    /**
    * Serviço de registro. 
    */
      services::RegistryService* registryService;

    /**
    * Intervalo de tempo que determina quando a credencial expira. 
    */
      Lease lease;

    /**
    * Credencial de identificação do usuário frente ao barramento. 
    */
      Credential* credential;

    /**
    * Host de localização do barramento. 
    */
      char* hostBus;

    /**
    * Porta de localização do barramento. 
    */
      unsigned short portBus;

    /**
    * Mutex 
    */
      IT_Mutex* mutex;

    /**
    * Possíveis estados para a conexão. 
    */
      enum ConnectionStates {
        CONNECTED,
        DISCONNECTED
      };

    /**
    * Indica o estado da conexão. 
    */
      ConnectionStates connectionState;

      unsigned long timeRenewing;

      void commandLineParse(
        int argc,
        char** argv);

    /**
    * Inicializa um valor default para o host e porta do barramento. 
    */
      void initialize();

    /**
    * Cria implicitamente um ORB e um POA. 
    */
      void createOrbPoa();

    /**
    * Registra os interceptadores cliente e servidor. 
    */
      void registerInterceptors();

    /**
    * Cria um estado novo. 
    */
      void newState();

      IT_Thread renewLeaseIT_Thread;

    /**
    * Thread responsável pela renovação da credencial do usuário que está 
    * logado neste barramento.
    */
      class RenewLeaseThread : public IT_ThreadBody {
        private:
          Openbus* bus;
        public:
          RenewLeaseThread(Openbus* _bus);
          void* run();
      };
      friend class Openbus::RenewLeaseThread;

      Openbus(
        int argc,
        char** argv);

      Openbus(
        int argc,
        char** argv,
        char* host,
        unsigned short port);

    public:

    /**
    * Fornece a única instância do barramento.
    * A localização do barramento pode ser fornecida através dos parâmetros
    *   de linha comando -OpenbusHost e -OpenbusPort.
    * @warning Caso o usuário esteje criando um ORB explicitamente ou 
    *   utilizando um ORB externo, a instanciação da classe Openbus 
    *   deve ocorrer antes da chamada orb_init().
    *
    * @param[in] argc
    * @param[in] argv
    *
    * @return Openbus
    */

      static Openbus* getInstance(
        int argc,
        char** argv);

    /**
    * Fornece a única instância do barramento.
    * A localização do barramento é fornecida através dos parâmetros host e
    * port.
    * @warning Caso o usuário esteje criando um ORB explicitamente ou 
    *   utilizando um ORB externo, a instanciação da classe Openbus 
    *   deve ocorrer antes da chamada orb_init().
    *
    * @param[in] argc
    * @param[in] argv
    * @param[in] host Máquina em que se encontra o barramento.
    * @param[in] port A porta do barramento
    *
    * @return Openbus
    */
      static Openbus* getInstance(
        int argc,
        char** argv,
        char* host,
        unsigned short port);

    /**
    * Informa o estado de conexão com o barramento.
    *
    * @return true caso a conexão esteja ativa, ou false, caso
    * contrário.
    */
      bool isConnected();

    /** 
    *  Termination Handler disponível para a classe IT_TerminationHandler()
    *  Este método desfaz a conexão para cada instância de barramento.
    *
    *  @param signalType
    */
      static void terminationHandlerCallback(long signalType);

      ~Openbus();

    /**
    *  Inicializa uma referência a um barramento.
    *  Um ORB e POA são criado implicitamente.
    *  Os parâmetros argc e argv são repassados para a função 
    *   CORBA::ORB_init().
    *  A fábrica de componentes SCS é criada.
    *  Os argumentos Openbus de linha de comando (argc e argv) são tratados.
    */
      void init();

    /**
    *  Retorna o ORB utilizado.
    *  @return ORB
    */
      CORBA::ORB* getORB();

    /**
    *  Retorna o RootPOA.
    *
    *  OBS: A chamada a este método ativa o POAManager.
    *
    *  @return POA
    */
      PortableServer::POA* getRootPOA();

    /**
    * Retorna a fábrica de componentes. 
    * @return Fábrica de componentes
    */
      scs::core::ComponentBuilder* getComponentBuilder();

    /**
    * Retorna a credencial interceptada pelo interceptador servidor. 
    * @return Credencial. \see openbusidl::acs::Credential
    */
      Credential_var getInterceptedCredential();

    /**
    * Retorna o serviço de acesso. 
    * @return Serviço de acesso
    */
      services::AccessControlService* getAccessControlService();

    /**
    * Retorna o serviço de registro. 
    * @return Serviço de registro
    */
      services::RegistryService* getRegistryService();

    /**
    * Retorna a credencial de identificação do usuário frente ao barramento. 
    * @return credencial
    */
      Credential* getCredential();

    /**
    * Retorna o intervalo de tempo que determina quando a credencial expira. 
    * @return lease
    */
      Lease getLease();

    /**
    *  Realiza uma tentativa de conexão com o barramento.
    *
    *  @param[in] user Nome do usuário.
    *  @param[in] password Senha do usuário.
    *  @throw LOGIN_FAILURE O par nome de usuário e senha não foram validados.
    *  @throw CORBA::SystemException Alguma falha de comunicação com o 
    *    barramento ocorreu.
    *  @return  Se a tentativa de conexão for bem sucedida, uma instância que 
    *    representa o serviço é retornada.
    */
      services::RegistryService* connect(
        const char* user,
        const char* password)
        throw (CORBA::SystemException, LOGIN_FAILURE);

    /**
    *  Realiza uma tentativa de conexão com o barramento utilizando o
    *    mecanismo de certificação para o processo de login.
    *
    *  @param[in] entity Nome da entidade a ser autenticada através de um
    *    certificado digital.
    *  @param[in] privateKeyFilename Nome do arquivo que armazena a chave
    *    privada do serviço.
    *  @param[in] ACSCertificateFilename Nome do arquivo que armazena o
    *    certificado do serviço.
    *  @throw LOGIN_FAILURE O par nome de usuário e senha não foram validados.
    *  @throw CORBA::SystemException Alguma falha de comunicação com o 
    *    barramento ocorreu.
    *  @throw SECURITY_EXCEPTION Falha na manipulação da chave privada da 
    *    entidade ou do certificado do ACS.
    *  @return  Se a tentativa de conexão for bem sucedida, uma instância que 
    *    representa o serviço é retornada.
    */
      services::RegistryService* connect(
        const char* entity,
        const char* privateKeyFilename,
        const char* ACSCertificateFilename)
        throw (CORBA::SystemException, LOGIN_FAILURE, SECURITY_EXCEPTION);

    /**
    *  Desfaz a conexão atual.
    *  Uma requisição remota logout() é realizada.
    *  Antes da chamada logout() um estado de *desconectando* é assumido,
    *  impedindo assim que a renovação de credencial seja realizada durante
    *  o processo.
    *
    *  @return Caso a conexão seja desfeita, true é retornado, caso contrário,
    *  o valor de retorno é false.
    */
      bool disconnect();

    /**
    * Loop que processa requisições CORBA. [execução do orb->run()]. 
    */
      void run();

    /**
    * Finaliza a execução do ORB.
    *
    * @param[in] bool force Se a finalização deve ser forçada ou não.
    */
      void finish(bool force);

  };
}

#endif


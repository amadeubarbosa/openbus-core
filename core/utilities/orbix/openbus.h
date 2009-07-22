/**
* \mainpage API - Openbus Orbix C++
* \file openbus.h
*/

#ifndef OPENBUS_H_
#define OPENBUS_H_

#include "verbose.h"
#include "stubs/access_control_service.hh"
#include "services/RegistryService.h"
#include "stubs/session_service.hh"

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
* \brief Stubs dos servi�os b�sicos.
*/
namespace openbusidl {

/**
* \brief Stub do servi�o de acesso.
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
* \brief Falha no processo de login, ou seja, o par nome de usu�rio e senha n�o
* foi validado.
*/
  class LOGIN_FAILURE : public runtime_error {
    public:
      LOGIN_FAILURE(const string& msg = "") : runtime_error(msg) {}
  };

/**
* \brief Falha na manipula��o da chave privada da entidade ou do certificado 
* ACS.
*/
  class SECURITY_EXCEPTION : public runtime_error {
    public:
      SECURITY_EXCEPTION(const string& msg = "") : runtime_error(msg) {}
  };

/**
* \brief N�o h� conex�o estabelecida com nenhum barramento.
*/
  class NO_CONNECTED : public runtime_error {
    public:
      NO_CONNECTED(const string& msg = "") : runtime_error(msg) {}
  };

/**
* \brief N�o � poss�vel obter o servi�o de sess�o no barramento em uso.
*/
  class NO_SESSION_SERVICE : public runtime_error {
    public:
      NO_SESSION_SERVICE(const string& msg = "") : runtime_error(msg) {}
  };

typedef openbusidl::acs::Credential_var Credential_var;

  /**
  * \brief Representa um barramento.
  */
  class Openbus {
    private:

    /**
    * Mutex 
    */
      static IT_Mutex mutex;

    /**
    * A inst�ncia �nica do barramento.
    */
      static Openbus* bus;

    /**
    * Par�metro argc da linha de comando. 
    */
      int _argc;

    /**
    * Par�metro argv da linha de comando. 
    */
      char** _argv;
      
    /**
    * Ponteiro para o stub do servi�o de acesso.
    */
      openbusidl::acs::IAccessControlService* iAccessControlService;

    /**
    * Ponteiro para o stub do servi�o de sess�o.
    */
      openbusidl::ss::ISessionService* iSessionService;

    /**
    * Ponteiro para a faceta ILeaseProvider. 
    */
      openbusidl::acs::ILeaseProvider* iLeaseProvider;

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
    * F�brica de componentes SCS. 
    */
      scs::core::ComponentBuilder* componentBuilder;

    /**
    * Gerenciador do POA. 
    */
      PortableServer::POAManager_var poa_manager;

    /**
    * Servi�o de registro. 
    */
      services::RegistryService* registryService;

    /**
    * Intervalo de tempo que determina quando a credencial expira. 
    */
      Lease lease;

    /**
    * Tipo da callback para a notifica��o de que um lease expirou.
    */
      typedef void (*LeaseExpiredCallback)();

    /**
    * Conjunto de callbacks registradas para a notifica��o da 
    * expira��o do lease.
    */
      static std::set<LeaseExpiredCallback> leaseExpiredCallbackSet;

    /**
    * Credencial de identifica��o do usu�rio frente ao barramento. 
    */
      Credential* credential;

    /**
    * Host de localiza��o do barramento. 
    */
      string hostBus;

    /**
    * Porta de localiza��o do barramento. 
    */
      unsigned short portBus;

    /**
    * Poss�veis estados para a conex�o. 
    */
      enum ConnectionStates {
        CONNECTED,
        DISCONNECTED
      };

    /**
    * Indica o estado da conex�o. 
    */
      ConnectionStates connectionState;

    /**
    * Intervalo de tempo que determina quando que a credencial ser� renovada.
    */
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
      
    /**
    * Cria o proxy para o servi�o de acesso.
    */
      void createProxyToIAccessControlService();

    /**
    * Cria o objeto registryService.
    */
      services::RegistryService* setRegistryService();

      IT_Thread renewLeaseIT_Thread;

    /**
    * Thread respons�vel pela renova��o da credencial do usu�rio que est� 
    * logado neste barramento.
    */
      class RenewLeaseThread : public IT_ThreadBody {
        public:
          RenewLeaseThread();
          void* run();
      };
      friend class Openbus::RenewLeaseThread;

    /**
    * Thread respons�vel pela renova��o de credencial.
    */
      static RenewLeaseThread* renewLeaseThread;

      Openbus();

    public:

    #ifdef VERBOSE
      static Verbose* verbose;
    #endif

      ~Openbus();

    /**
    * Fornece a �nica inst�ncia do barramento.
    *
    * @return Openbus
    */
      static Openbus* getInstance();

    /**
    * Inicializa uma refer�ncia a um barramento.
    *
    * Um ORB e POA s�o criado implicitamente.
    * A f�brica de componentes SCS � criada.
    * Os argumentos Openbus de linha de comando (argc e argv) s�o tratados.
    * A localiza��o do barramento pode ser fornecida atrav�s dos par�metros
    *   de linha comando -OpenbusHost e -OpenbusPort.
    *
    * @param[in] argc
    * @param[in] argv
    */
      void init(
        int argc,
        char** argv);

    /**
    * Inicializa uma refer�ncia a um barramento.
    *
    * Um ORB e POA s�o criado implicitamente.
    * A f�brica de componentes SCS � criada.
    * Os argumentos Openbus de linha de comando (argc e argv) s�o tratados.
    * A localiza��o do barramento � fornecida atrav�s dos par�metros host e
    * port.
    *
    * @param[in] argc
    * @param[in] argv
    * @param[in] host M�quina em que se encontra o barramento.
    * @param[in] port A porta do barramento
    */
      void init(
        int argc,
        char** argv,
        char* host,
        unsigned short port);

    /**
    * Informa o estado de conex�o com o barramento.
    *
    * @return true caso a conex�o esteja ativa, ou false, caso
    * contr�rio.
    */
      bool isConnected();

    /** 
    *  Termination Handler dispon�vel para a classe IT_TerminationHandler()
    *
    *  @param signalType
    */
      static void terminationHandlerCallback(long signalType);

    /**
    *  Retorna o ORB utilizado.
    *  @return ORB
    */
      CORBA::ORB* getORB();

    /**
    *  Retorna o RootPOA.
    *
    *  OBS: A chamada a este m�todo ativa o POAManager.
    *
    *  @return POA
    */
      PortableServer::POA* getRootPOA();

    /**
    * Retorna a f�brica de componentes. 
    * @return F�brica de componentes
    */
      scs::core::ComponentBuilder* getComponentBuilder();

    /**
    * Retorna a credencial interceptada pelo interceptador servidor. 
    * @return Credencial. \see openbusidl::acs::Credential
    */
      Credential_var getInterceptedCredential();

    /**
    * Retorna o servi�o de acesso. 
    * @return Servi�o de acesso
    */
      openbusidl::acs::IAccessControlService* getAccessControlService();

    /**
    * Retorna o servi�o de registro. 
    * @return Servi�o de registro
    */
      services::RegistryService* getRegistryService();

    /**
    * Retorna o servi�o de sess�o. 
    * @return Servi�o de sess�o.
    */
      openbusidl::ss::ISessionService* getSessionService() 
        throw(NO_CONNECTED, NO_SESSION_SERVICE);

    /**
    * Retorna a credencial de identifica��o do usu�rio frente ao barramento. 
    * @return credencial
    */
      Credential* getCredential();

    /**
    * Define uma credencial a ser utilizada no lugar da credencial corrente. 
    * �til para fornecer uma credencial com o campo delegate preenchido.
    * 
    * @param[in] credential Credencial a ser utilizada nas requisi��es a serem
    *   realizadas.
    */
      void setThreadCredential(Credential* credential);

    /**
    * Registra uma callback para a notifica��o de que o lease da credencial
    * de identifica��o do usu�rio, frente ao barramento, expirou.
    *
    * @param[in] A callback a ser registrada.
    * @return True se a callback foi registrada com sucesso, ou false 
    * se a callback j� estava registrada.
    */
      bool addLeaseExpiredCallback(
        LeaseExpiredCallback leaseExpiredCallback);
    /**
    * Remove uma callback previamente registra para a notifica��o de lease 
    * expirado.
    *
    * @param[in] A callback a ser removida.
    * @return True se a callback foi removida com sucesso, ou false 
    * caso contr�rio.
    */
      bool removeLeaseExpiredCallback(
        LeaseExpiredCallback leaseExpiredCallback);

    /**
    *  Realiza uma tentativa de conex�o com o barramento.
    *
    *  @param[in] user Nome do usu�rio.
    *  @param[in] password Senha do usu�rio.
    *  @throw LOGIN_FAILURE O par nome de usu�rio e senha n�o foram validados.
    *  @throw CORBA::SystemException Alguma falha de comunica��o com o 
    *    barramento ocorreu.
    *  @return  Se a tentativa de conex�o for bem sucedida, uma inst�ncia que 
    *    representa o servi�o � retornada.
    */
      services::RegistryService* connect(
        const char* user,
        const char* password)
        throw (CORBA::SystemException, LOGIN_FAILURE);

    /**
    *  Realiza uma tentativa de conex�o com o barramento utilizando o
    *    mecanismo de certifica��o para o processo de login.
    *
    *  @param[in] entity Nome da entidade a ser autenticada atrav�s de um
    *    certificado digital.
    *  @param[in] privateKeyFilename Nome do arquivo que armazena a chave
    *    privada do servi�o.
    *  @param[in] ACSCertificateFilename Nome do arquivo que armazena o
    *    certificado do servi�o.
    *  @throw LOGIN_FAILURE O par nome de usu�rio e senha n�o foram validados.
    *  @throw CORBA::SystemException Alguma falha de comunica��o com o 
    *    barramento ocorreu.
    *  @throw SECURITY_EXCEPTION Falha na manipula��o da chave privada da 
    *    entidade ou do certificado do ACS.
    *  @return  Se a tentativa de conex�o for bem sucedida, uma inst�ncia que 
    *    representa o servi�o � retornada.
    */
      services::RegistryService* connect(
        const char* entity,
        const char* privateKeyFilename,
        const char* ACSCertificateFilename)
        throw (CORBA::SystemException, LOGIN_FAILURE, SECURITY_EXCEPTION);

    /**
    *  Desfaz a conex�o atual.
    *  Uma requisi��o remota logout() � realizada.
    *  Antes da chamada logout() um estado de *desconectando* � assumido,
    *  impedindo assim que a renova��o de credencial seja realizada durante
    *  o processo.
    *
    *  @return Caso a conex�o seja desfeita, true � retornado, caso contr�rio,
    *  o valor de retorno � false.
    */
      bool disconnect();

    /**
    * Loop que processa requisi��es CORBA. [execu��o do orb->run()]. 
    */
      void run();

    /**
    * Finaliza a execu��o do ORB.
    *
    * @param[in] bool force Se a finaliza��o deve ser for�ada ou n�o.
    */
      void finish(bool force);

  };
}

#endif


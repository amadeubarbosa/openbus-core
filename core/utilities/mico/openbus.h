/**
* \mainpage API - Openbus Orbix C++
* \file openbus.h
*/

#ifndef OPENBUS_H_
#define OPENBUS_H_

#include "verbose.h"
#include "stubs/access_control_service.h"
#include "openbus/util/Helper.h"
#include "stubs/session_service.h"

#include "openbus/interceptors/ORBInitializerImpl.h"
#include <ComponentBuilderMico.h>

#include <CORBA.h>

#include <stdexcept>
#include <string>
#include <map>
#include <set>

using namespace openbusidl::acs;

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
  * \brief Credencial de acesso ao barramento.
  */

  }
}

/**
* \brief openbus
*/
namespace openbus {

  typedef set<string> MethodSet;
  typedef map<string, MethodSet*> IfaceMap;

/**
* \brief Falha no processo de login, ou seja, o par nome de usuário e senha não
* foi validado.
*/
  class LOGIN_FAILURE : public runtime_error {
    public:
      LOGIN_FAILURE(const string& msg = "") : runtime_error(msg) {}
  };

/**
* \brief Falha no mecanismo de autenticação por certificado digital.
* Algumas possíveis causas:
*  + Não foi possível obter o desafio.
*  + Falha na manipulação de uma chave privada ou pública.
*  + Falha na manipulação de um certificado.
*/
  class SECURITY_EXCEPTION : public runtime_error {
    public:
      SECURITY_EXCEPTION(const string& msg = "") : runtime_error(msg) {}
  };

/**
* \brief Não há conexão estabelecida com nenhum barramento.
*/
  class NO_CONNECTED : public runtime_error {
    public:
      NO_CONNECTED(const string& msg = "") : runtime_error(msg) {}
  };

/**
* \brief Não é possível obter o serviço de sessão no barramento em uso.
*/
  class NO_SESSION_SERVICE : public runtime_error {
    public:
      NO_SESSION_SERVICE(const string& msg = "") : runtime_error(msg) {}
  };

  /**
  * \brief Representa um barramento.
  */
  class Openbus {
    public:
      class LeaseExpiredCallback;

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
    * Ponteiro para o stub do serviço de acesso.
    */
      openbusidl::acs::IAccessControlService_var iAccessControlService;

    /**
    * Ponteiro para o stub do serviço de registro.
    */
      openbusidl::rs::IRegistryService* iRegistryService;

    /**
    * Ponteiro para o stub do serviço de sessão.
    */
      openbusidl::ss::ISessionService* iSessionService;

    /**
    * Ponteiro para a faceta ILeaseProvider. 
    */
      openbusidl::acs::ILeaseProvider_var iLeaseProvider;

    /**
    * Inicializador do ORB. 
    */
      static interceptors::ORBInitializerImpl* ini;

    /**
    * ORB. 
    */
      CORBA::ORB_var orb;

    /**
    * POA.
    */
      PortableServer::POA_var poa;

    /**
    * Fábrica de componentes SCS. 
    */
      scs::core::ComponentBuilder* componentBuilder;

    /**
    * Gerenciador do POA. 
    */
      PortableServer::POAManager_var poa_manager;

    /**
    * Intervalo de tempo que determina quando a credencial expira. 
    */
      Lease lease;

    /**
    * Credencial de identificação do usuário frente ao barramento. 
    */
      openbusidl::acs::Credential* credential;

    /**
    * Máquina em que está o barramento. 
    */
      string hostBus;

    /**
    * A porta da máquina em que se encontra o barramento.
    */
      unsigned short portBus;

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

    /**
    * Intervalo de tempo que determina quando que a credencial será renovada.
    */
      unsigned long timeRenewing;

    /**
    * Especifica se o tempo de renovação de credencial é fixo.
    */
      bool timeRenewingFixe;

    /**
    * Cria o objeto registryService.
    */
      IfaceMap ifaceMap;

    /**
    * Trata os parâmetros de linha de comando.
    */
      void commandLineParse();

    /**
    * Inicializa um valor default para a máquina e porta do barramento. 
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
    * Cria o proxy para o serviço de acesso.
    */
      void createProxyToIAccessControlService();

    /**
    * Desconexão local.
    */
      void localDisconnect();

    /**
    * Cria o objeto registryService.
    */
      void setRegistryService();

    #ifdef MULTITHREAD
      class RunThread : public MICOMT::Thread {
        public:
          void _run(void*);
      };
      friend class Openbus::RunThread;

      static RunThread* runThread;
    #endif

      Openbus();

      class RenewLeaseCallback : public CORBA::DispatcherCallback {
        private:
        /**
        * Callback registrada para a notificação da 
        * expiração do lease.
        */
          LeaseExpiredCallback* leaseExpiredCallback;
        public:
          RenewLeaseCallback();
          void setLeaseExpiredCallback(LeaseExpiredCallback* obj);
          void callback(CORBA::Dispatcher* dispatcher, Event event);
      };

    /**
    * Callbak responsável por renovar a credencial.
    */
      RenewLeaseCallback renewLeaseCallback;

    public:

    #ifdef VERBOSE
      static Verbose* verbose;
    #endif

      ~Openbus();

    /**
    * Fornece a única instância do barramento.
    *
    * @return Openbus
    */
      static Openbus* getInstance();

    /**
    * Inicializa uma referência a um barramento.
    *
    * Um ORB e um POA são criados implicitamente.
    * A fábrica de componentes SCS é criada.
    * Os argumentos Openbus de linha de comando (argc e argv) são tratados.
    * Parâmetros de linha de comando: 
    *   "-OpenbusHost": Host do barramento.
    *   "-OpenbusPort": Porta do barramento.
    *   "-TimeRenewing": Tempo em milisegundos de renovação da credencial.
    *
    * @param[in] argc
    * @param[in] argv
    */
      void init(
        int argc,
        char** argv);

    /**
    * Inicializa uma referência a um barramento.
    *
    * Um ORB e um POA são criados implicitamente.
    * A fábrica de componentes SCS é criada.
    * Os argumentos Openbus de linha de comando (argc e argv) são tratados.
    * Parâmetros de linha de comando: 
    *   "-OpenbusHost": Máquina em que se encontra o barramento.
    *   "-OpenbusPort": Porta do barramento.
    *   "-TimeRenewing": Tempo em milisegundos de renovação da credencial.
    *
    * @param[in] argc
    * @param[in] argv
    * @param[in] host Máquina em que se encontra o barramento.
    * @param[in] port A porta da máquina em que se encontra o barramento.
    */
      void init(
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
      openbusidl::acs::IAccessControlService* getAccessControlService();

    /**
    * Retorna o serviço de registro. 
    * @return Serviço de registro
    */
      openbusidl::rs::IRegistryService* getRegistryService();

    /**
    * Retorna o serviço de sessão. 
    * @return Serviço de sessão.
    */
      openbusidl::ss::ISessionService* getSessionService() 
        throw(NO_CONNECTED, NO_SESSION_SERVICE);

    /**
    * Retorna a credencial de identificação do usuário frente ao barramento. 
    * @return credencial
    */
      Credential* getCredential();

    /**
    * Define uma credencial a ser utilizada no lugar da credencial corrente. 
    * Útil para fornecer uma credencial com o campo delegate preenchido.
    * 
    * @param[in] credential Credencial a ser utilizada nas requisições a serem
    *   realizadas.
    */
      void setThreadCredential(Credential* credential);

    /**
    * Representa uma callback para a notificação de que um lease expirou.
    */
      class LeaseExpiredCallback {
        public:
          virtual void expired() = 0;
      };

    /**
    * Registra uma callback para a notificação de que o lease da credencial
    * de identificação do usuário, frente ao barramento, expirou.
    *
    * @param[in] A callback a ser registrada.
    * @return True se a callback foi registrada com sucesso, ou false 
    * se a callback já estava registrada.
    */
      void addLeaseExpiredCallback(
        LeaseExpiredCallback* leaseExpiredCallback);

    /**
    * Remove uma callback previamente registra para a notificação de lease 
    * expirado.
    *
    * @param[in] A callback a ser removida.
    * @return True se a callback foi removida com sucesso, ou false 
    * caso contrário.
    */
      void removeLeaseExpiredCallback();

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
      openbusidl::rs::IRegistryService* connect(
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
    *  @throw SECURITY_EXCEPTION Falha no mecanismo de autenticação por 
    *    certificado digital.
    *    Algumas possíveis causas:
    *     + Não foi possível obter o desafio.
    *     + Falha na manipulação de uma chave privada ou pública.
    *     + Falha na manipulação de um certificado.
    *       entidade ou do certificado do ACS.
    *  @return  Se a tentativa de conexão for bem sucedida, uma instância que 
    *    representa o serviço é retornada.
    */
      openbusidl::rs::IRegistryService* connect(
        const char* entity,
        const char* privateKeyFilename,
        const char* ACSCertificateFilename)
        throw (CORBA::SystemException, LOGIN_FAILURE, SECURITY_EXCEPTION);

    /**
    *  Desfaz a conexão atual.
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

    /**
    * Configura os métodos da interface devem ser interceptados pelo servidor.
    *
    * @param[in] string iface RepID da interface.
    * @param[in] string method Nome do método.
    * @param[in] bool interceptable Indica se o método deve ser interceptado.
    *
    */
      void setInterceptable(string iface, string method, bool interceptable);

    /**
    * Consulta se o método está sendo interceptado.
    *
    * @param[in] string iface RepID da interface.
    * @param[in] string method Nome do método.
    *
    * @return true se o método é interceptado ou false caso contrário.
    */
      bool isInterceptable(string iface, string method);
  };
}

#endif


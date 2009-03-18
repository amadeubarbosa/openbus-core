/*
** openbus.h
*/

#ifndef OPENBUS_H_
#define OPENBUS_H_

#include "services/AccessControlService.h"
#include "services/RegistryService.h"

#include "openbus/common/ORBInitializerImpl.h"
#include <scs/core/ComponentBuilderOrbix.h>

#include <omg/orb.hh>
#include <it_ts/thread.h>
#include <it_ts/mutex.h>

using namespace openbusidl::acs;
IT_USING_NAMESPACE_STD

namespace openbus {
  class COMMUNICATION_FAILURE {};
  class LOGIN_FAILURE {};

  typedef openbusidl::acs::Credential_var Credential_var;

  class Openbus {
    private:

    /* Parâmetro argc da linha de comando. */
      int _argc;

    /* Parâmetro argv da linha de comando. */
      char** _argv;

    /* Inicializador do ORB. */
      static common::ORBInitializerImpl* ini;

    /* ORB */
      CORBA::ORB* orb;

    /* POA */
      PortableServer::POA* poa;

    /* Fábrica de componentes SCS. */
      scs::core::ComponentBuilder* componentBuilder;

    /* Gerenciador do POA. */
      PortableServer::POAManager_var poa_manager;

    /* Serviço de acesso. */
      services::AccessControlService* accessControlService;

    /* Serviço de registro. */
      services::RegistryService* registryService;

    /* Intervalo de tempo que determina quando a credencial expira. */
      Lease lease;

    /* Credencial de identificação do usuário frente ao barramento. */
      Credential* credential;

    /* Host de localização do barramento. */
      char* hostBus;

    /* Porta de localização do barramento. */
      unsigned short portBus;

    /* Mutex */
      IT_Mutex* mutex;

    /* Possíveis estados para a conexão. */
      enum ConnectionStates {
        CONNECTED,
        DISCONNECTED
      };

    /* Indica o estado da conexão. */
      ConnectionStates connectionState;

      unsigned long timeRenewing;

      void commandLineParse(
        int argc,
        char** argv);

    /* Inicializa um valor default para o host e porta do barramento. */
      void initializeHostPort();

    /* Cria implicitamente um ORB e um POA. */
      void createOrbPoa();

    /* Registra os interceptadores cliente e servidor. */
      void registerInterceptors();

    /* Cria um estado novo. */
      void newState();

      IT_Thread renewLeaseIT_Thread;

      class RenewLeaseThread : public IT_ThreadBody {
        private:
          Openbus* bus;
        public:
          RenewLeaseThread(Openbus* _bus);
          void* run();
      };

    public:

    /* Construtor
    *  Cria uma referência para um determinado barramento.
    *  A localização do barramento pode ser fornecida através dos parâmetros de linha comando
    *  -OpenbusHost e -OpenbusPort.
    */
      Openbus(
        int argc,
        char** argv);

    /* Construtor
    *  Cria uma referência para um determinado barramento.
    *  A localização do barramento é fornecida através dos parâmetros host e port.
    */
      Openbus(
        int argc,
        char** argv,
        char* host,
        unsigned short port);

      ~Openbus();

    /* Inicializa uma referência a um barramento.
    *  Um ORB e POA são criado implicitamente.
    *  Os parâmetros argc e argv são repassados para a função CORBA::ORB_init().
    *  A fábrica de componentes SCS é criada.
    *  Os argumentos Openbus de linha de comando (argc e argv) são tratados.
    */
      void init();

    /* Inicializa uma referência a um barramento.
    *  Um ORB e POA são passados explicitamente pelo usuário.
    *  A fábrica de componentes SCS é criada.
    *  Os argumentos Openbus de linha de comando (argc e argv) são tratados.
    */
      void init(
        CORBA::ORB_ptr _orb,
        PortableServer::POA* _poa);

    /* Retorna a fábrica de componentes. */
      scs::core::ComponentBuilder* getComponentBuilder();

    /* Retorna a credencial interceptada pelo interceptador servidor. */
      Credential_var getCredentialIntercepted();

    /* Retorna o serviço de acesso. */
      services::AccessControlService* getAccessControlService();

    /* Retorna a credencial de identificação do usuário frente ao barramento. */
      Credential* getCredential();

    /* Retorna o intervalo de tempo que determina quando a credencial expira. */
      Lease getLease();

    /* Realiza uma tentativa de conexão com o barramento.
    *  Parâmetros de entrada:
    *    user: Nome do usuário.
    *    password: Senha do usuário.
    *  Se a tentativa for bem sucedida, uma instância que representa o serviço de registro é retornada,
    *  caso contrário duas exceções podem ser lançadas:
    *    LOGIN_FAILURE: O par nome de usuário e senha não foram validados.
    *    COMMUNICATION_FAILURE: Alguma falha de comunicação com o barramento ocorreu.
    */
      services::RegistryService* connect(
        const char* user,
        const char* password)
        throw (COMMUNICATION_FAILURE, LOGIN_FAILURE);

    /* Desfaz a conexão atual.
    *  Uma requisição remota logout() é realizada.
    *  Antes da chamada logout() um estado de *desconectando* é assumido,
    *  impedindo assim que a renovação de credencial seja realizada durante
    *  o processo.
    *  Se nenhuma conexão estiver ativa, o valor de retorno é false.
    *  Retorno: Caso a conexão seja desfeita, true é retornado, caso contrário,
    *  o valor de retorno é false.
    */
      bool disconnect();

    /* Loop que processa requisições CORBA. [execução do orb->run()]. */
      void run();
  };
}

#endif

/*
** OpenBus Demo - Mico
** server.cpp
*/

#include <fstream>
#include <iostream>
#include <CORBA.h>
#include <csignal>

#include <openbus.h>
#include <ComponentBuilder.h>

#include "stubs/hello.h"

using namespace std;
using namespace tecgraf::openbus::core::v1_05;

openbus::Openbus* bus;
registry_service::IRegistryService* registryService;
char* registryId;
scs::core::ComponentContext* componentContext;

class HelloImpl : virtual public POA_demoidl::hello::IHello {
  private:
    scs::core::ComponentContext* componentContext;
    HelloImpl(scs::core::ComponentContext* componentContext) {
      this->componentContext = componentContext;
    }
  public:
    static PortableServer::ServantBase* instantiate(
      scs::core::ComponentContext* componentContext) 
    {
      return (PortableServer::ServantBase*) new HelloImpl(componentContext);
    }
    static void destruct(void* obj) {
      delete (HelloImpl*) obj;
    }
    void sayHello() throw(CORBA::SystemException) {
      cout << "Servant diz: HELLO!" << endl;
      access_control_service::Credential_var credential = 
        bus->getInterceptedCredential();
      cout << "Usuario OpenBus que fez a chamada: " << credential->owner.in()
        << endl;
    };
};

void termination_handler(int p) {
  cout << "Encerrando o processo servidor..." << endl;
  try {
    registryService->unregister(registryId);
  } catch(CORBA::Exception& e) {
    cout << "Nao foi possivel remover a oferta de servico." << endl;
  }
  try {
    if (bus->isConnected()) {
      bus->disconnect();
    }
  } catch(CORBA::Exception& e) {
    cout << "Nao foi possivel se desconectar corretamente do barramento." 
      << endl; 
  }
  delete bus;
}

int main(int argc, char* argv[]) {
  signal(SIGINT, termination_handler);
  bus = openbus::Openbus::getInstance();

  bus->init(argc, argv);

  cout << "Conectando no barramento..." << endl;

/* Conexao com o barramento atraves de certificado. */
  try {
    registryService = bus->connect("HelloService", "HelloService.key",
      "AccessControlService.crt");
  } catch (CORBA::SystemException& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Falha na comunicacao. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Par usuario/senha invalido. *" << endl;
    exit(-1);
  } catch (openbus::SECURITY_EXCEPTION& e) {
    cout << e.what() << endl;
    exit(-1);
  }

  cout << "Conexao com o barramento estabelecida com sucesso!" << endl;

/* Fabrica de componentes */
  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();

/* Definicao do componente. */
  scs::core::ComponentId componentId;
  componentId.name = "HelloComponent";
  componentId.major_version = '1';
  componentId.minor_version = '0';
  componentId.patch_version = '0';
  componentId.platform_spec = "nenhuma";

/* Descricao das facetas. */
  std::list<scs::core::ExtendedFacetDescription> extFacets;
  scs::core::ExtendedFacetDescription helloDesc;
  helloDesc.name = "IHello";
  helloDesc.interface_name = "IDL:demoidl/hello/IHello:1.0";
  helloDesc.instantiator = HelloImpl::instantiate;
  helloDesc.destructor = HelloImpl::destruct;
  extFacets.push_back(helloDesc);
  componentContext = componentBuilder->newComponent(extFacets, componentId);

  openbus::util::PropertyListHelper* propertyListHelper = \
    new openbus::util::PropertyListHelper();

/* Criacao de uma *oferta de servico*. */
  registry_service::ServiceOffer serviceOffer;
  serviceOffer.properties = propertyListHelper->getPropertyList();
  serviceOffer.member = componentContext->getIComponent();
  delete propertyListHelper;

  cout << "Registrando servico IHello no barramento..." << endl;

/* Registro do servico no barramento. */
  registryService->_cxx_register(serviceOffer, registryId);
  cout << "Servico IHello registrado." << endl;
  cout << "Aguardando requisicoes..." << endl;

  bus->run();

  return 0;
}


/*
** OpenBus Demo - Orbix 6.3
** server.cpp
*/

#include <fstream>
#include <iostream>
#include <omg/orb.hh>
#include <it_ts/thread.h>
#include <it_ts/termination_handler.h>

#include <openbus.h>
#include <ComponentBuilder.h>

#include "stubs/helloS.hh"

using namespace std;

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
    void sayHello() 
      throw(CORBA::SystemException) {
      cout << "Servant diz: HELLO!" << endl;
      access_control_service::Credential_var credential = 
        bus->getInterceptedCredential();
      cout << "Usuario OpenBus que fez a chamada: " << credential->owner.in()
        << endl;
    };
};

static void myTerminationHandler(long signal) {
  cout << "Encerrando o processo servidor..." << endl;
  try {
    registryService->unregister(registryId);
  } catch(CORBA::Exception& e) {
    cout << "Não foi possível remover a oferta de serviço." << endl;
  }

  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
  map<string, string>* errors = componentBuilder->deactivateComponent(componentContext);
  map<string, string>::iterator it;
  for ( it = errors->begin() ; it != errors->end(); it++ ) {
    string error = (string) (*it).second;
    cout << "Erro ao desativar a faceta " << error << "." << endl;
  }
  delete errors;
  delete componentContext;
  openbus::Openbus::terminationHandlerCallback(signal);
}

int main(int argc, char* argv[]) {
  IT_TerminationHandler termination_handler(myTerminationHandler);

  bus = openbus::Openbus::getInstance();

  bus->init(argc, argv);

  cout << "Conectando no barramento..." << endl;

/* Conexão com o barramento através de certificado. */
  try {
    registryService = bus->connect("HelloService", "HelloService.key",
      "AccessControlService.crt");
  } catch (CORBA::SystemException& e) {
    cout << "** Não foi possível se conectar ao barramento. **" << endl \
         << "* Falha na comunicação. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Não foi possível se conectar ao barramento. **" << endl \
         << "* Par usuário/senha inválido. *" << endl;
    exit(-1);
  } catch (openbus::SECURITY_EXCEPTION& e) {
    cout << e.what() << endl;
    exit(-1);
  }

  cout << "Conexão com o barramento estabelecida com sucesso!" << endl;

/* Fábrica de componentes */
  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();

/* Definição do componente. */
  scs::core::ComponentId componentId;
  componentId.name = "HelloComponent";
  componentId.major_version = '1';
  componentId.minor_version = '0';
  componentId.patch_version = '0';
  componentId.platform_spec = "nenhuma";

/* Descrição das facetas. */
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

/* Criação de uma *oferta de serviço*. */
  openbus::util::ServiceOffer serviceOffer;
  serviceOffer.properties = propertyListHelper->getPropertyList();
  serviceOffer.member = componentContext->getIComponent();
  delete propertyListHelper;

  cout << "Registrando serviço IHello no barramento..." << endl;

/* Registro do serviço no barramento. */
  registryService->_cxx_register(serviceOffer, registryId);
  cout << "Serviço IHello registrado." << endl;
  cout << "Aguardando requisições..." << endl;

  bus->run();

  return 0;
}


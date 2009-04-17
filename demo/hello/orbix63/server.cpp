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
#include <scs/core/ComponentBuilderOrbix.h>

#include "stubs/helloS.hh"

using namespace std;

IT_USING_NAMESPACE_STD

openbus::Openbus* bus;
openbus::services::RegistryService* registryService;
char* registryId;

class HelloImpl : virtual public POA_Hello {
  private:
    scs::core::ComponentContext* componentContext;
    HelloImpl(scs::core::ComponentContext* componentContext) {
      this->componentContext = componentContext;
    }
  public:
    static void* instantiate(scs::core::ComponentContext* componentContext) {
      return (void*) new HelloImpl(componentContext);
    }
    static void destruct(void* obj) {
      delete (HelloImpl*) obj;
    }
    void sayHello() IT_THROW_DECL((CORBA::SystemException)) {
      cout << endl << "Servant diz: HELLO!" << endl;
      openbus::Credential_var credential = bus->getCredentialIntercepted();
      cout << "Usuario OpenBus que fez a chamada: " << credential->owner.in() << endl;
    };
};

static void myTerminationHandler(long signal) {
  registryService->unregister(registryId);
  openbus::Openbus::terminationHandlerCallback(signal);
}

int main(int argc, char* argv[]) {
  IT_TerminationHandler termination_handler(myTerminationHandler);

  bus = new openbus::Openbus(argc, argv);

/* Se o usuário desejar criar o seu próprio ORB/POA:
*  CORBA::ORB* orb = CORBA::ORB_init(argc, argv);
*  CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
*  PortableServer::POA* poa = PortableServer::POA::_narrow(poa_obj);
*  PortableServer::POAManager_var poa_manager = poa->the_POAManager();
*  poa_manager->activate();
*
*  bus->init(orb, poa);
*/
  bus->init();

/* Conexão com o barramento. */
  try {
    registryService = bus->connect("tester", "tester");
  } catch (openbus::COMMUNICATION_FAILURE& e) {
    cout << "** Não foi possível se conectar ao barramento. **" << endl \
         << "* Falha na comunicação. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Não foi possível se conectar ao barramento. **" << endl \
         << "* Par usuário/senha inválido. *" << endl;
    exit(-1);
  }

/* Criação do componente */
  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
  scs::core::ComponentId componentId;
  componentId.name = "HelloComponent";
  componentId.major_version = '1';
  componentId.minor_version = '0';
  componentId.patch_version = '0';
  componentId.platform_spec = "nenhuma";
  std::list<scs::core::ExtendedFacetDescription> extFacets;
  scs::core::ExtendedFacetDescription helloDesc;
  helloDesc.name = "IHello";
  helloDesc.interface_name = "IDL:demoidl/hello/IHello:1.0";
  helloDesc.instantiator = HelloImpl::instantiate;
  helloDesc.destructor = HelloImpl::destruct;
  extFacets.push_back(helloDesc);
  scs::core::ComponentContext* componentContext = componentBuilder->newFullComponent(extFacets, componentId);

/* Definição de uma lista de propriedades que caracteriza o serviço de interesse.
*  O trabalho de criação da lista e facilitado pelo uso da classe PropertyListHelper.
*/
  openbus::services::PropertyListHelper* propertyListHelper = new openbus::services::PropertyListHelper();
  propertyListHelper->add("facet", "IHello");

/* Criação de uma *oferta de serviço*. */
  openbus::services::ServiceOffer serviceOffer;
  serviceOffer.properties = propertyListHelper->getPropertyList();
  serviceOffer.member = componentContext->getIComponent();
  /* Registro do serviço no barramento. */
  registryService->Register(serviceOffer, registryId);
  cout << "\n\nServiço HELLO registrado no OpenBus..." << endl;

  bus->run();

  return 0;
}

/*
** OpenBus Demo - Orbix 6.3
** server.cpp
*/

#include <fstream>
#include <iostream>
#include <omg/orb.hh>
#include <it_ts/thread.h>

#include <openbus.h>
#include <scs/core/ComponentBuilderOrbix.h>

#include "stubs/helloS.hh"

using namespace std;

IT_USING_NAMESPACE_STD

openbus::Openbus* bus;

class HelloImpl : virtual public POA_Hello {
  private:
    scs::core::ComponentContext* componentContext;
    HelloImpl(scs::core::ComponentContext* componentContext) {
    #ifdef VERBOSE
      cout << "[HelloImpl::HelloImpl() BEGIN]" << endl;
    #endif
      this->componentContext = componentContext;
    #ifdef VERBOSE
      cout << "[HelloImpl::HelloImpl() END]" << endl;
    #endif
    }
  public:
    static void* instantiate(scs::core::ComponentContext* componentContext) {
      return (void*) new HelloImpl(componentContext);
    }
    void sayHello() IT_THROW_DECL((CORBA::SystemException)) {
      cout << endl << "Servant diz: HELLO!" << endl;
      openbus::Credential_var credential = bus->getCredentialIntercepted();
      cout << "Usuario OpenBus que fez a chamada: " << credential->owner.in() << endl;
    };
};

int main(int argc, char* argv[]) {
  char* registryId;
  openbus::services::RegistryService* registryService;

  bus = new openbus::Openbus(argc, argv);

/* Se o usuario desejar criar o seu proprio ORB/POA:
*  CORBA::ORB* orb = CORBA::ORB_init(argc, argv);
*  CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
*  PortableServer::POA* poa = PortableServer::POA::_narrow(poa_obj);
*  PortableServer::POAManager_var poa_manager = poa->the_POAManager();
*  poa_manager->activate();
*
*  bus->init(orb, poa);
*/
  bus->init();

/* Conex�o com o barramento. */
  try {
    registryService = bus->connect("tester", "tester");
  } catch (openbus::COMMUNICATION_FAILURE& e) {
    cout << "** N�o foi poss�vel se conectar ao barramento. **" << endl \
         << "* Falha na comunica��o. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** N�o foi poss�vel se conectar ao barramento. **" << endl \
         << "* Par usu�rio/senha inv�lido. *" << endl;
    exit(-1);
  }

/* Cria��o do componente */
  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
  scs::core::ComponentId componentId;
  componentId.name = "HelloComponent";
  componentId.major_version = '1';
  componentId.minor_version = '0';
  componentId.patch_version = '0';
  componentId.platform_spec = "none";
  std::list<scs::core::ExtendedFacetDescription> extFacets;
  scs::core::ExtendedFacetDescription helloDesc;
  helloDesc.name = "IHello";
  helloDesc.interface_name = "IDL:Hello:1.0";
  helloDesc.instantiator = HelloImpl::instantiate;
  extFacets.push_back(helloDesc);
  scs::core::ComponentContext* componentContext = componentBuilder->newFullComponent(extFacets, componentId);

/* Defini��o de uma lista de propriedades que caracteriza o servi�o de interesse.
*  O trabalho de cria��o da lista e facilitado pelo uso da classe PropertyListHelper.
*/
  openbus::services::PropertyListHelper* propertyListHelper = new openbus::services::PropertyListHelper();
  propertyListHelper->add("facet", "IHello");

/* Cria��o de uma *oferta de servi�o*. */
  openbus::services::ServiceOffer so;
  so.properties = propertyListHelper->getPropertyList();
  so.member = componentContext->getIComponent();
  /* Registro do servi�o no barramento. */
  registryService->Register(so, registryId);
  cout << "\n\nServi�o HELLO registrado no OpenBus..." << endl;
  bus->run();

  return 0;
}

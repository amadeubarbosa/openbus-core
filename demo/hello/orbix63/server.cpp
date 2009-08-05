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
#include <ComponentBuilderOrbix.h>

#include "stubs/helloS.hh"

using namespace std;

IT_USING_NAMESPACE_STD

openbus::Openbus* bus;
openbus::services::RegistryService* registryService;
char* registryId;
scs::core::ComponentContext* componentContext;

class HelloImpl : virtual public POA_demoidl::hello::IHello {
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
      cout << "Servant diz: HELLO!" << endl;
      openbusidl::acs::Credential_var credential = 
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
    cout << "N�o foi poss�vel remover a oferta de servi�o." << endl;
  }
  delete componentContext;
  openbus::Openbus::terminationHandlerCallback(signal);
}

int main(int argc, char* argv[]) {
  IT_TerminationHandler termination_handler(myTerminationHandler);

  bus = openbus::Openbus::getInstance();

  bus->init(argc, argv);

  cout << "Conectando no barramento..." << endl;

/* Conex�o com o barramento atrav�s de certificado. */
  try {
    registryService = bus->connect("HelloService", "HelloService.key",
      "AccessControlService.crt");
  } catch (CORBA::SystemException& e) {
    cout << "** N�o foi poss�vel se conectar ao barramento. **" << endl \
         << "* Falha na comunica��o. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** N�o foi poss�vel se conectar ao barramento. **" << endl \
         << "* Par usu�rio/senha inv�lido. *" << endl;
    exit(-1);
  } catch (openbus::SECURITY_EXCEPTION& e) {
    cout << e.what() << endl;
    exit(-1);
  }

  cout << "Conex�o com o barramento estabelecida com sucesso!" << endl;

/* F�brica de componentes */
  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();

/* Defini��o do componente. */
  scs::core::ComponentId componentId;
  componentId.name = "HelloComponent";
  componentId.major_version = '1';
  componentId.minor_version = '0';
  componentId.patch_version = '0';
  componentId.platform_spec = "nenhuma";

/* Descri��o das facetas. */
  std::list<scs::core::ExtendedFacetDescription> extFacets;
  scs::core::ExtendedFacetDescription helloDesc;
  helloDesc.name = "IHello";
  helloDesc.interface_name = "IDL:demoidl/hello/IHello:1.0";
  helloDesc.instantiator = HelloImpl::instantiate;
  helloDesc.destructor = HelloImpl::destruct;
  extFacets.push_back(helloDesc);
  componentContext = componentBuilder->newComponent(extFacets, componentId);

  openbus::services::PropertyListHelper* propertyListHelper = \
    new openbus::services::PropertyListHelper();

/* Cria��o de uma *oferta de servi�o*. */
  openbus::services::ServiceOffer serviceOffer;
  serviceOffer.properties = propertyListHelper->getPropertyList();
  serviceOffer.member = componentContext->getIComponent();
  delete propertyListHelper;

  cout << "Registrando servi�o IHello no barramento..." << endl;

/* Registro do servi�o no barramento. */
  registryService->Register(serviceOffer, registryId);
  cout << "Servi�o IHello registrado." << endl;
  cout << "Aguardando requisi��es..." << endl;

  bus->run();

  return 0;
}


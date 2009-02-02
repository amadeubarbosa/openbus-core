/*
** OpenBus Demo - Orbix 6.3
** server.cpp
*/

#include <fstream>
#include <iostream>
#include <omg/orb.hh>
#include <it_ts/thread.h>

#include <openbus.h>

#include "helloS.hh"

using namespace std;

IT_USING_NAMESPACE_STD

openbus::Openbus* bus;

class Hello_impl : virtual public POA_Hello {
  public:
    void sayHello() IT_THROW_DECL((CORBA::SystemException)) {
      cout << endl << "Servant diz: HELLO!" << endl;
      openbusidl::acs::Credential_var credential = bus->getCredentialIntercepted();
      cout << "Usuário OpenBus que fez a chamada: " << credential->owner.in() << endl;
    };
};

Hello_impl* hello;

int main(int argc, char* argv[]) {
  char* registryId;
  openbus::services::RegistryService* registryService;

  bus = new openbus::Openbus(argc, argv);

/* Se o usuario desejar criar o seu proprio ORB/POA.
  CORBA::ORB* orb = CORBA::ORB_init(argc, argv);
  CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
  PortableServer::POA* poa = PortableServer::POA::_narrow(poa_obj);
  PortableServer::POAManager_var poa_manager = poa->the_POAManager();
  poa_manager->activate();

  bus->init(orb, poa);
*/
  bus->init();

/* Conexao com o barramento. */
  try {
    registryService = bus->connect("tester", "tester");
  } catch (openbus::COMMUNICATION_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Falha na comunicacao. *" << endl;
    exit(-1);
  } catch (openbus::LOGIN_FAILURE& e) {
    cout << "** Nao foi possivel se conectar ao barramento. **" << endl \
         << "* Par usuario/senha inválido. *" << endl;
    exit(-1);
  }

  hello = new Hello_impl;

  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
  scs::core::IComponentImpl* IComponent = componentBuilder->createComponent("component", 1, "facet", "IDL:Hello:1.0", hello);

  openbusidl::rs::PropertyList_var p = new openbusidl::rs::PropertyList(5);
  p->length(1);
  openbusidl::rs::Property_var property = new openbusidl::rs::Property;
  property->name = "facet";
  openbusidl::rs::PropertyValue_var propertyValue = new openbusidl::rs::PropertyValue(5);
  propertyValue->length(1);
  propertyValue[0] = "IHello";
  property->value = propertyValue;
  p[0] = property;
  openbusidl::rs::ServiceOffer so;
  so.properties = p;
  so.member = IComponent->_this();

  registryService->Register(so, registryId);
  cout << "Serviço HELLO registrado no OpenBus..." << endl;

  bus->run();

  return 0;
}

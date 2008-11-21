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
using namespace openbusidl::acs;
using namespace openbusidl::rs;
using namespace openbus;
using namespace openbus::common;

IT_USING_NAMESPACE_STD

Openbus* bus;

class Hello_impl : virtual public POA_Hello {
  public:
    void sayHello() IT_THROW_DECL((CORBA::SystemException)) {
      cout << endl << "Servant diz: HELLO!" << endl;
      openbus::common::ServerInterceptor* serverInterceptor = bus->getServerInterceptor();
      openbusidl::acs::Credential_var credential = serverInterceptor->getCredential();
      cout << "Usuário OpenBus que fez a chamada: " << credential->owner.in() << endl;
    };
};

Hello_impl* hello;

int main(int argc, char* argv[]) {
  char* registryId;
  openbus::services::RegistryService* registryService;

  bus = Openbus::getInstance();

/* Se o usuario desejar criar o seu proprio ORB/POA.
  bus->init(argc, argv, orb, root_poa);
*/

/* Criacao implicita do ORB. */
  bus->init(argc, argv);

/* Conexao com o barramento. */
  try {
    registryService = bus->connect("localhost", 2089, "tester", "tester");
  } catch (const char* errmsg) {
    cout << "** Nao foi possivel se conectar ao barramento." << endl << errmsg << endl;
    exit(-1);
  }

  hello = new Hello_impl;

  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
  scs::core::IComponentImpl* IComponent = componentBuilder->createComponent("component", 1, "facet", "IDL:Hello:1.0", hello);

  PropertyList_var p = new PropertyList(5);
  p->length(1);
  Property_var property = new Property;
  property->name = "facet";
  PropertyValue_var propertyValue = new PropertyValue(5);
  propertyValue->length(1);
  propertyValue[0] = "IHello";
  property->value = propertyValue;
  p[0] = property;
  ServiceOffer so;
  so.properties = p;
  so.member = IComponent->_this();

  registryService->Register(so, registryId);
  cout << "Serviço HELLO registrado no OpenBus..." << endl;

  bus->run();

  return 0;
}

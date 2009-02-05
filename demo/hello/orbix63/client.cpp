/*
** OpenBus Demo - Orbix 6.3
** client.cpp
*/

#include <fstream>
#include <iostream>

#include "hello.hh"
#include <openbus.h>

using namespace std;

int main(int argc, char* argv[]) {
  openbus::Openbus* bus;
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

  CORBA::ULong idx = 0;
  openbusidl::rs::PropertyList_var p = new openbusidl::rs::PropertyList(5);
  p->length(1);
  openbusidl::rs::ServiceOfferList_var soList = new openbusidl::rs::ServiceOfferList(5);
  soList->length(5);
  openbusidl::rs::Property_var property = new openbusidl::rs::Property;
  property->name = "facet";
  openbusidl::rs::PropertyValue_var propertyValue = new openbusidl::rs::PropertyValue(5);
  propertyValue->length(1);
  propertyValue[0] = "IHello";
  property->value = propertyValue;
  p[0] = property;
  soList = registryService->find(p);
  openbusidl::rs::ServiceOffer so;
  so = soList[idx];

  scs::core::IComponent* component = so.member;
  CORBA::Object* obj = component->getFacet("IDL:Hello:1.0");
  Hello* hello = Hello::_narrow(obj);
  hello->sayHello();

  bus->disconnect();

  return 0;
}

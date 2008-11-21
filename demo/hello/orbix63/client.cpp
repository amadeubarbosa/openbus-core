/*
** OpenBus Demo - Orbix 6.3
** client.cpp
*/

#include <fstream>
#include <iostream>

#include "hello.hh"
#include <openbus.h>

using namespace std;
using namespace openbusidl::acs;
using namespace openbusidl::rs;
using namespace openbus;
using namespace openbus::common;

int main(int argc, char* argv[]) {
  Openbus* bus;
  openbus::services::RegistryService* registryService;

  bus = Openbus::getInstance();

/* Criacao implicita do ORB. */
  bus->init(argc, argv);

/* Conexao com o barramento. */
  try {
    registryService = bus->connect("localhost", 2089, "tester", "tester");
  } catch (const char* errmsg) {
    cout << "** Nao foi possivel se conectar ao barramento." << endl << errmsg << endl;
    exit(-1);
  }

  CORBA::ULong idx = 0;
  PropertyList_var p = new PropertyList(5);
  p->length(1);
  ServiceOfferList_var soList = new ServiceOfferList(5);
  soList->length(5);
  Property_var property = new Property;
  property->name = "facet";
  PropertyValue_var propertyValue = new PropertyValue(5);
  propertyValue->length(1);
  propertyValue[0] = "IHello";
  property->value = propertyValue;
  p[0] = property;
  soList = registryService->find(p);
  ServiceOffer so;
  so = soList[idx];

  scs::core::IComponent* component = so.member;
  CORBA::Object* obj = component->getFacet("IDL:Hello:1.0");
  Hello* hello = Hello::_narrow(obj);
  hello->sayHello();

  bus->logout();

  return 0;
}

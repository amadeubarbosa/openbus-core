/*
** Demo Hello - OiL
** client.cpp
*/

#include <openbus.h>
#include "helloStub.h"

#include <iostream>

using namespace openbus;
using namespace std;

int main(int argc, char** argv) {
  services::IAccessControlService* accessControlService;
  services::IRegistryService* registryService;

  Openbus* bus = Openbus::getInstance();
  bus->init(argc, argv);

/* Conexao com o barramento. */
  services::Credential* credential = new services::Credential();
  services::Lease* lease = new services::Lease();
  try {
    accessControlService = bus->connect("localhost", 2089, "tester", "tester", credential, lease);
  } catch (const char* errmsg) {
    cout << "** Nao foi possivel se conectar ao barramento." << endl << errmsg << endl;
    exit(-1);
  }

/* Adquirindo o servico de registro. */
  registryService = accessControlService->getRegistryService();

/* Procurando o servico hello. */
  services::PropertyList* propertyList = new services::PropertyList;
  services::Property* property = new services::Property;
  property->name = "facet";
  property->value = new services::PropertyValue;
  property->value->newmember("IHello");
  propertyList->newmember(property);
  services::ServiceOfferList* serviceOfferList = registryService->find(propertyList);
  if (!serviceOfferList) {
    cout << "** Nenhum servico hello foi encontrado no barramento." << endl;
    exit(-1);
  }
  services::ServiceOffer* serviceOffer = serviceOfferList->getmember(0);

/* Obtendo o servico hello. */
  scs::core::IComponent* member = serviceOffer->member;
  member->loadidlfile("../idl/hello.idl");
  IHello* hello = member->getFacet <IHello> ("IDL:demoidl/hello/IHello:1.0");

  hello->sayHello();

  return 0;
}

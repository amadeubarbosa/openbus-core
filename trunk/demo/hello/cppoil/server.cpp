/*
** Demo Hello - OiL
** server.cpp
*/

#include <openbus.h>
#include "hello.hpp"
int tolua_hello_open (lua_State*);

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

/* Criando um componente que disponibiliza uma faceta do servico hello. */
  tolua_hello_open(bus->getLuaVM());
  IHello* hello = new IHello;
  scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
  componentBuilder->loadIDLFile("../idl/hello.idl");
  scs::core::IComponent* iComponent = componentBuilder->createComponent("component", '1', '0', '0', "none", "facet", "IDL:demoidl/hello/IHello:1.0", "IHello", hello);

/* Registrando no barramento o servico hello. */
  services::PropertyList* propertyList = new services::PropertyList;
  services::Property* property = new services::Property;
  property->name = "facet";
  services::PropertyValue* propertyValue = new services::PropertyValue;
  propertyValue->newmember("IHello");
  property->value = propertyValue;
  propertyList->newmember(property);
  services::ServiceOffer* serviceOffer = new services::ServiceOffer;
  serviceOffer->properties = propertyList;
  serviceOffer->member = iComponent;
  char* RegistryIdentifier;
  registryService->Register(serviceOffer, RegistryIdentifier);

/* O processo fica no aguardo de requisicoes CORBA referentes ao servico hello. */
  bus->run();

  return 0;
}

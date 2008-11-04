/*
** Demo Hello
** server.cpp
*/

#include <openbus.h>
#include "hello.hpp"
int tolua_hello_open (lua_State*);

#include <iostream>

using namespace openbus;
using namespace std;

int main(int argc, char** argv) {
  Openbus* openbus = Openbus::getInstance();

/* Conexao com o barramento. */
  services::Credential* credential = new services::Credential();
  services::Lease* lease = new services::Lease();
  services::IAccessControlService* acs;
  try {
    acs = openbus->connect("localhost", 2089, "tester", "tester", credential, lease);
  } catch (const char* errmsg) {
    cout << "** Nao foi possivel se conectar ao barramento." << endl << errmsg << endl;
    exit(-1);
  }

/* Adquirindo o servico de registro. */
  services::IRegistryService* rgs = acs->getRegistryService();

/* Criando um componente que disponibiliza uma faceta do servico hello. */
  scs::core::IComponent* member = new scs::core::IComponent();
  member->loadidlfile("../idl/hello.idl");
  tolua_hello_open(openbus->getLuaVM());
  IHello* hello = new IHello;
  member->addFacet("hello", "IDL:demoidl/hello/IHello:1.0", "IHello", hello);

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
  serviceOffer->member = member;
  char* RegistryIdentifier;
  rgs->Register(serviceOffer, RegistryIdentifier);

/* O processo fica no aguardo de requisições CORBA referentes ao servico hello. */
  openbus->run();

  return 0;
}

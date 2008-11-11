/*
** OpenBus Demo - Orbix 6.3
** server.cpp
*/

#include <fstream>
#include <iostream>
#include <omg/orb.hh>

#include <openbus.h>

#include "helloS.hh"

using namespace std;
using namespace openbusidl::acs;
using namespace openbusidl::rs;
using namespace openbus::common;

IT_USING_NAMESPACE_STD

char* id;
IRegistryService_var rgs;
ORBInitializerImpl* ini;
openbus::common::ServerInterceptor* serverInterceptor;

class Hello_impl : virtual public POA_Hello {
  public:
    void sayHello() IT_THROW_DECL((CORBA::SystemException)) {
      cout << endl << "Servant diz: HELLO!" << endl;
      serverInterceptor = ini->getServerInterceptor();
      openbusidl::acs::Credential_var c = serverInterceptor->getCredential();
      cout << "Usuário OpenBus que fez a chamada: " << c->owner.in() << endl;
    };
};

CORBA::ORB_ptr orb = CORBA::ORB::_nil();
Hello_impl* hello;
PortableServer::POA_var root_poa;

int main(int argc, char* argv[]) {
  Lease lease = 0;
  Credential_var credential;
  openbus::common::CredentialManager credentialManager;

  ini = new ORBInitializerImpl(&credentialManager);
  PortableInterceptor::register_orb_initializer(ini);

  orb = CORBA::ORB_init(argc, argv);
  CORBA::Object_var poa_obj = orb->resolve_initial_references("RootPOA");
  root_poa = PortableServer::POA::_narrow(poa_obj);
  PortableServer::POAManager_var poa_manager = root_poa->the_POAManager();

  CORBA::Object_var obj = orb->string_to_object("corbaloc::localhost:2089/ACS");
  IAccessControlService_var acs = IAccessControlService::_narrow(obj);

  bool status = acs->loginByPassword("tester", "tester", credential, lease);
  if (status) {
    credentialManager.setValue(credential);
    cout << "SERVER" << endl;
    cout << "Login efetuado no Openbus." << endl;
    cout << "owner = " << credential->owner.in() << endl;
    cout << "identifier = " << credential->identifier.in() << endl;
  } else {
    return -1;
  }

  rgs = acs->getRegistryService();
  hello = new Hello_impl;

  scs::core::IComponentImpl* c = new scs::core::IComponentImpl("component", 1, orb, root_poa);

  c->addFacet("facet", "IDL:Hello:1.0", hello);
  poa_manager->activate();
  PropertyList_var p = new PropertyList(5);
  p->length(1);
  Property_var property = new Property;
  property->name = "type";
  PropertyValue_var propertyValue = new PropertyValue(5);
  propertyValue->length(1);
  propertyValue[0] = "type1";
  property->value = propertyValue;
  p[0] = property;
  ServiceOffer so;
  so.properties = p;
  so.member = c->_this();
  rgs->_cxx_register(so, id);
  cout << "Serviço HELLO registrado no OpenBus..." << endl;
  orb->run();

  return 0;
}

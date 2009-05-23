/*
** OpenBus Demo - Mico 2.3.12
** server.cpp
*/

#include <fstream>
#include <iostream>
#include <CORBA.h>

#include <openbus.h>

#include "hello.h"

using namespace std;
using namespace openbusidl::acs;
using namespace openbusidl::rs;
using namespace openbus::common;

char* id;
IRegistryService_var rgs;
ORBInitializerImpl* ini;
openbus::common::ServerInterceptor* serverInterceptor;

class Hello_impl : virtual public POA_Hello {
  public:
    void sayHello() {
      cout << endl<< "Servant diz: HELLO!" << endl;
      serverInterceptor = ini->getServerInterceptor();
      cout << "Usuario OpenBus que fez a chamada: " << serverInterceptor->getCredential()->owner.in() << endl;
    };
};

CORBA::ORB_ptr orb = CORBA::ORB::_nil();
Hello_impl* hello;
PortableServer::POA_var poa;

class ORBThread : virtual public MICOMT::Thread {
  public:
    void _run(void*)
    {
      orb->run();
      poa->destroy (TRUE, TRUE);
      delete hello;
    }
};

int main(int argc, char* argv[]) {
  Lease lease = 0;
  Credential_var credential;
  openbus::common::CredentialManager credentialManager;

  ini = new ORBInitializerImpl(&credentialManager);
  PortableInterceptor::register_orb_initializer(ini);

  orb = CORBA::ORB_init(argc, argv);
  CORBA::Object_var poaobj = orb->resolve_initial_references ("RootPOA");
  poa = PortableServer::POA::_narrow (poaobj);
  PortableServer::POAManager_var mgr = poa->the_POAManager();

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

  ORBThread* main = new ORBThread;
  main->start();
  scs::core::IComponentImpl* c = new scs::core::IComponentImpl("component", '1', '0', '0', "", orb, poa);
  c->addFacet("facet", "IDL:Hello:1.0", hello);
  mgr->activate ();
  PropertyList_var p = new PropertyList(5);
  p->length(1);
  Property_var property = new Property;
  property->name = "type";
  PropertyValue_var propertyValue = new PropertyValue(5);
  propertyValue->length(1);
  propertyValue[(MICO_ULong) 0] = "type1";
  property->value = propertyValue;
  p[(MICO_ULong) 0] = property;
  ServiceOffer so;
  so.properties = p;
  so.member = c->_this();
  rgs->_cxx_register(so, id);
  main->wait();
  return 0;
}

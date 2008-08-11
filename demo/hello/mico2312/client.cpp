/*
** OpenBus Demo - Mico 2.3.12
** client.cpp
*/

#include <fstream>
#include <iostream>

#include "hello.h"
#include <openbus.h>

using namespace std;
using namespace openbusidl::acs;
using namespace openbusidl::rs;
using namespace openbus::common;

int main(int argc, char* argv[]) {
  Lease lease = 0;
  Credential_var credential;
  CredentialManager credentialManager;

  ORBInitializerImpl* ini = new ORBInitializerImpl(&credentialManager);
  PortableInterceptor::register_orb_initializer(ini);

  CORBA::ORB_var orb = CORBA::ORB_init(argc, argv);
  CORBA::Object_var poaobj = orb->resolve_initial_references ("RootPOA");
  PortableServer::POA_var poa = PortableServer::POA::_narrow (poaobj);
  PortableServer::POAManager_var mgr = poa->the_POAManager();

  CORBA::Object_var obj = orb->string_to_object("corbaloc::localhost:2089/ACS");
  IAccessControlService_var acs = IAccessControlService::_narrow(obj);

  bool status = acs->loginByPassword("tester", "tester", credential, lease);
  if (status) {
    credentialManager.setValue(credential);
    cout << endl << "CLIENT" << endl;
    cout << "Login efetuado no Openbus." << endl;
    cout << "entityName = " << credential->entityName.in() << endl;
    cout << "identifier = " << credential->identifier.in() << endl;
  } else {
    return -1;
  }

  CORBA::ULong idx = 0;
  IRegistryService_var rgs = acs->getRegistryService();
  PropertyList_var p = new PropertyList(5);
  p->length(1);
  ServiceOfferList_var soList = new ServiceOfferList(5);
  soList->length(5);
  Property_var property = new Property;
  property->name = "type";
  PropertyValue_var propertyValue = new PropertyValue(5);
  propertyValue->length(1);
  propertyValue[(MICO_ULong) 0] = "type1";
  property->value = propertyValue;
  p[(MICO_ULong) 0] = property;
  soList = rgs->find(p);
  ServiceOffer so;
  so = soList[ idx ];
  ::scs::core::IComponent_var member;
  member = so.member;
  obj = member->getFacet("IDL:Hello:1.0");
/*test*/
/*  printf("%p", member->getFacetByName("facet"));
  printf("%p", member->getFacetByName("facet2"));
  ::scs::core::ComponentId* cId = member->getComponentId();
  printf("%s %lu", cId->name.in(), cId->version);*/
/**/
  Hello_var hello = Hello::_narrow(obj);
  hello->sayHello();
  CORBA::release(orb);
  return 0;
}

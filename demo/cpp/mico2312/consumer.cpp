/*
** OpenBus Demo - Mico 2.3.12
** consumer.cpp
*/

#include <fstream>
#include <iostream>

#include "hello.h"
#include "scs.h"
#include "access_control_service.h"
#include "registry_service.h"
#include "mico/common/ClientInterceptor.h"
#include "mico/common/ORBInitializerImpl.h"

using namespace std ;
using namespace openbusidl::acs ;
using namespace openbusidl::rs ;
using namespace orbinitializerimpl ;

int main( int argc, char* argv[] ) {
  Lease lease = 0 ;
  Credential_var credential ;
  CredentialHolder credentialHolder ;

  ORBInitializerImpl* ini =  new ORBInitializerImpl( &credentialHolder ) ;
  PortableInterceptor::register_orb_initializer( ini ) ;

  CORBA::ORB_var orb = CORBA::ORB_init( argc, argv ) ;
  CORBA::Object_var poaobj = orb->resolve_initial_references ("RootPOA");
  PortableServer::POA_var poa = PortableServer::POA::_narrow (poaobj);
  PortableServer::POAManager_var mgr = poa->the_POAManager();

  CORBA::Object_var obj = orb->string_to_object( "corbaloc::localhost:2089/ACS" ) ;
  IAccessControlService_var acs = IAccessControlService::_narrow( obj ) ;

  bool status = acs->loginByPassword( "csbase", "csbLDAPtest", credential, lease ) ;
  if ( status ) {
    credentialHolder.identifier = credential->identifier.in() ;
    credentialHolder.entityName = credential->entityName.in() ;
    cout << "\nLogin efetuado no Openbus.\nentityName=" << \
    credentialHolder.entityName << "\nidentifier=" << \
    credentialHolder.identifier << "\n\n" ;
  } else {
    return -1 ;
  }

  CORBA::ULong idx = 0 ;
  IRegistryService_var rgs = acs->getRegistryService() ;
  PropertyList p ;
  ServiceOfferList_var soList = new ServiceOfferList ;
  soList = rgs->find( "type1", p ) ;
  ServiceOffer so ;
  cout << (soList[ idx ].type).in() ;
  so = soList[ idx ] ;
  ::scs::core::IComponent_var member;
  member = so.member ;
  obj = member->getFacet( "IDL:Hello:1.0" ) ;
/*test*/
/*  printf( "%p", member->getFacetByName( "facet" ) ) ;
  printf( "%p", member->getFacetByName( "facet2" ) ) ;
  ::scs::core::ComponentId* cId = member->getClassId() ;
  printf( "%s %lu", cId->name.in(), cId->version ) ;*/
/**/
  Hello_var hello = Hello::_narrow( obj ) ;
  hello->sayHello() ;
  CORBA::release( orb ) ;
  return 0 ;
}

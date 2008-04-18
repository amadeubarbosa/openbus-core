/*
* rgs/RGSTestSuite.cpp
*/

#ifndef RGS_TESTSUITE_H
#define RGS_TESTSUITE_H

#include <stdlib.h>
#include <string.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>
#include "hello.hpp"
int  tolua_hello_open (lua_State*) ;

using namespace openbus ;

class RGSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o ;
    services::IAccessControlService* acs ;
    services::IRegistryService* rgs ;
    common::CredentialManager* credentialManager ;
    common::ClientInterceptor* clientInterceptor ;
    services::Credential* credential ;
    services::Lease* lease ;
    char* RegistryIdentifier;
    services::ServiceOfferList* serviceOfferList ;
    services::Property* property ;
    services::PropertyList* propertyList ;
    services::PropertyValue* propertyValue ;
  public:
    void setUP() {
    }

    void testConstructor()
    {
      try {
        o = Openbus::getInstance() ;
        credentialManager = new common::CredentialManager ;
        const char* OPENBUS_HOME = getenv( "OPENBUS_HOME" ) ;
        char path[ 100 ] ;
        if ( OPENBUS_HOME == NULL )
        {
          throw "Error: OPENBUS_HOME environment variable is not defined." ;
        }
        strcpy( path, OPENBUS_HOME ) ;
        clientInterceptor = new common::ClientInterceptor( \
          strcat( path, "/core/conf/advanced/InterceptorsConfiguration.lua" ), \
          credentialManager ) ;
        o->setClientInterceptor( clientInterceptor ) ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testGetRGS()
    {
      try {
        acs = o->getACS( "corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0" ) ;
        credential = new services::Credential ;
        lease = new services::Lease ;
        acs->loginByPassword( "tester", "tester", credential, lease ) ;
        credentialManager->setValue( credential ) ;
        rgs = acs->getRegistryService() ;
        scs::core::IComponent* member = new scs::core::IComponent( "scs::core::IComponent Mock" ) ;
        propertyList = new services::PropertyList ;
        property = new services::Property ;
        property->name = "p1" ;
        services::PropertyValue p ;
        propertyValue = new services::PropertyValue ;
        propertyValue->newmember( "a" ) ;
        propertyValue->newmember( "b" ) ;
        propertyValue->newmember( "c" ) ;
        property->value = propertyValue ;
        propertyList->newmember(property) ;
        services::ServiceOffer* serviceOffer = new services::ServiceOffer ;
        serviceOffer->type = "type1" ;
        serviceOffer->description = "bla bla bla" ;
        serviceOffer->properties = propertyList ;
        serviceOffer->member = member ;
        rgs->Register(serviceOffer, RegistryIdentifier ) ;
        propertyList = new services::PropertyList ;
        property = new services::Property ;
        property->name = "p1" ;
        propertyValue = new services::PropertyValue ;
        propertyValue->newmember( "c" ) ;
        property->value = propertyValue ;
        propertyList->newmember( property ) ;
        serviceOfferList = rgs->find( "type1", propertyList ) ;
        TS_ASSERT( serviceOfferList != NULL ) ;
        TS_ASSERT( rgs->unregister( RegistryIdentifier) ) ;
        delete member ;
        delete serviceOfferList ;
      } catch ( const char* errmsg ) {
        TS_FAIL(errmsg) ;
      }
    }

    void testFind()
    {
      scs::core::IComponent* member = new scs::core::IComponent( "scs::core::IComponent Mock" ) ;
      services::PropertyList* propertyList = new services::PropertyList ;
      services::ServiceOffer* serviceOffer = new services::ServiceOffer ;
      serviceOffer->type = "X" ;
      serviceOffer->description = "bla" ;
      serviceOffer->properties = propertyList ;
      serviceOffer->member = member ;
      TS_ASSERT( rgs->Register( serviceOffer, RegistryIdentifier )) ;
      TS_ASSERT( rgs->find( "X", propertyList ) != NULL ) ;
      TS_ASSERT( rgs->find( "Y", propertyList ) == NULL ) ;
      TS_ASSERT( rgs->unregister( RegistryIdentifier) ) ;
      delete member ;
    }

    void testUpdate()
    {
      scs::core::IComponent* member = new scs::core::IComponent( "scs::core::IComponent Mock" ) ;
      services::PropertyList* propertyList = new services::PropertyList ;
      services::ServiceOffer* serviceOffer = new services::ServiceOffer ;
      serviceOffer->type = "X" ;
      serviceOffer->description = "bla" ;
      serviceOffer->properties = propertyList ;
      serviceOffer->member = member ;
      TS_ASSERT( rgs->Register( serviceOffer, RegistryIdentifier )) ;
      propertyList = new services::PropertyList ;
      property = new services::Property ;
      property->name = "p1" ;
      propertyValue = new services::PropertyValue ;
      propertyValue->newmember( "b" ) ;
      property->value = propertyValue ;
      propertyList->newmember( property ) ;
      TS_ASSERT( rgs->find( "X", propertyList ) == NULL ) ;
      propertyList = new services::PropertyList ;
      property = new services::Property ;
      property->name = "p1" ;
      propertyValue = new services::PropertyValue ;
      propertyValue->newmember( "c" ) ;
      propertyValue->newmember( "a" ) ;
      propertyValue->newmember( "b" ) ;
      property->value = propertyValue ;
      propertyList->newmember( property ) ;
      TS_ASSERT( rgs->update( RegistryIdentifier, propertyList ) ) ;
      propertyList = new services::PropertyList ;
      property = new services::Property ;
      property->name = "p1" ;
      propertyValue = new services::PropertyValue ;
      propertyValue->newmember( "b" ) ;
      property->value = propertyValue ;
      propertyList->newmember( property ) ;
      TS_ASSERT( rgs->find( "X", propertyList ) != NULL ) ;
      TS_ASSERT( rgs->unregister( RegistryIdentifier) ) ;
      delete member ;
    }

    void testFacets()
    {
      tolua_hello_open( Openbus::getLuaVM() ) ;
      hello* obj = new hello ;
      scs::core::IComponent* member = new scs::core::IComponent( "scs::core::IComponent" ) ;
      member->loadidl( "interface hello { void say_hello() ; };" ) ;
      member->addFacet( "Faceta01", "IDL:hello:1.0", "hello", obj ) ;
      member->addFacet( "Faceta02", "IDL:hello:1.0", "hello", obj ) ;
      services::PropertyList* propertyList = new services::PropertyList ;
      property = new services::Property ;
      property->name = "p1" ;
      propertyValue = new services::PropertyValue ;
      propertyValue->newmember( "b" ) ;
      property->value = propertyValue ;
      propertyList->newmember( property ) ;
      services::ServiceOffer* serviceOffer = new services::ServiceOffer ;
      serviceOffer->type = "WithFacets" ;
      serviceOffer->description = "bla" ;
      serviceOffer->properties = propertyList ;
      serviceOffer->member = member ;
      TS_ASSERT( rgs->Register( serviceOffer, RegistryIdentifier ) ) ;
      propertyList = new services::PropertyList ;
      property = new services::Property ;
      property->name = "facets" ;
      propertyValue = new services::PropertyValue ;
      propertyValue->newmember( "Faceta01" ) ;
      property->value = propertyValue ;
      propertyList->newmember( property ) ;
      TS_ASSERT( rgs->find( "WithFacets", propertyList ) != NULL ) ;
      obj = member->getFacet <hello> ( "IDL:hello:1.0" ) ;
      obj->say_hello() ;
      delete obj ;
      TS_ASSERT( rgs->unregister( RegistryIdentifier ) ) ;
      delete member ;
      delete acs ;
      delete rgs ;
    }
} ;

#endif

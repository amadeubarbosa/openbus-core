/*
* ses/SESTestSuite.h
*/

#ifndef SES_TESTSUITE_H
#define SES_TESTSUITE_H

#include <stdlib.h>
#include <string.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>

using namespace openbus ;

class SESTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o ;
    services::IAccessControlService* acs ;
    services::IRegistryService* rgs ;
    common::CredentialManager* credentialManager ;
    common::ClientInterceptor* clientInterceptor ;
    services::Credential* credential ;
    services::Lease* lease ;
    char* RegistryIdentifier;
    services::ServiceOffer* serviceOffer ;
    services::ServiceOfferList* serviceOfferList ;
    services::Property* property ;
    services::PropertyList* propertyList ;
    services::PropertyValue* propertyValue ;
    scs::core::IComponent* component ;
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
          strcat( path, "/conf/advanced/InterceptorsConfiguration.lua" ), \
          credentialManager ) ;
        o->setclientinterceptor( clientInterceptor ) ;
        acs = o->getACS( "corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0" ) ;
        credential = new services::Credential() ;
        lease = new services::Lease() ;
        acs->loginByPassword( "csbase", "csbLDAPtest", credential, lease ) ;
        credentialManager->setValue( credential ) ;
        rgs = acs->getRegistryService() ;
        serviceOfferList = rgs->find( "SessionService", NULL ) ;
        if ( serviceOfferList != NULL )
        {
          serviceOffer = serviceOfferList->getmember( 0 ) ;
          component = serviceOffer->member ;
          services::ISessionService* ses = component->getFacet <services::ISessionService> \
              ( "IDL:openbusidl/ss/ISessionService:1.0" ) ;
          scs::core::IComponent* c1 = new scs::core::IComponent( "membro1" ) ;
          scs::core::IComponent* c2 = new scs::core::IComponent( "membro2" ) ;
          char* mId ;
          services::ISession* s ;
          services::ISession* s2 ;
          ses->createSession( c1, s, mId ) ;
          s2 = ses->getSession() ;
          services::SessionIdentifier sId  = s->getIdentifier() ;
          services::SessionIdentifier sId2 = s2->getIdentifier() ;
          TS_ASSERT_SAME_DATA( sId, sId2, strlen( sId2 ) ) ;
          services::MemberIdentifier mId2 = s->addMember( c2 ) ;
          s->getMembers() ;
          s->removeMember( mId ) ;
          s->removeMember( mId2 ) ;
          delete s ;
          delete s2 ;
          delete c1 ;
          delete c2 ;
          delete ses ;
      }
        acs->logout( credential ) ;
        delete acs ;
        delete rgs ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

} ;

#endif

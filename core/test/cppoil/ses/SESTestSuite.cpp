/*
* ses/SESTestSuite.h
*/

#ifndef SES_TESTSUITE_H
#define SES_TESTSUITE_H

#include <string.h>
#include <stdlib.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>

#define BUFFER_SIZE 1024

using namespace openbus ;

class SESTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o ;
    services::IAccessControlService* acs ;
    services::IRegistryService* rgs ;
    services::Credential* credential ;
    services::Lease* lease ;
    char* RegistryIdentifier;
    services::ServiceOffer* serviceOffer ;
    services::ServiceOfferList* serviceOfferList ;
    services::Property* property ;
    services::PropertyList* propertyList ;
    services::PropertyValue* propertyValue ;
    scs::core::IComponent* component ;
    char BUFFER[BUFFER_SIZE];
    char* OPENBUS_SERVER_HOST;
    unsigned short OPENBUS_SERVER_PORT;
    char* OPENBUS_USERNAME;
    char* OPENBUS_PASSWORD;
  public:
    void setUP() {
    }

    void testConstructor()
    {
      try {
        o = Openbus::getInstance() ;
        Lua_State* LuaVM = o->getLuaVM();
        const char* OPENBUS_HOME = getenv("OPENBUS_HOME");
        strcpy(BUFFER, OPENBUS_HOME);
        strcat(BUFFER, "/core/test/cppoil/config.lua");
        if (luaL_dofile(LuaVM, BUFFER)) {
          printf("Não foi possível carregar o arquivo %s.\n", BUFFER);
          exit(-1);
        }
        lua_getglobal(LuaVM, "OPENBUS_SERVER_HOST");
        OPENBUS_SERVER_HOST = (char*) lua_tostring(LuaVM, -1);
        lua_getglobal(LuaVM, "OPENBUS_SERVER_PORT");
        OPENBUS_SERVER_PORT = lua_tonumber(LuaVM, -1);
        lua_getglobal(LuaVM, "OPENBUS_USERNAME");
        OPENBUS_USERNAME = (char*) lua_tostring(LuaVM, -1);
        lua_getglobal(LuaVM, "OPENBUS_PASSWORD");
        OPENBUS_PASSWORD = (char*) lua_tostring(LuaVM, -1);
        lua_pop(LuaVM, 4);
        acs = o->getACS(OPENBUS_SERVER_HOST, OPENBUS_SERVER_PORT) ;
        credential = new services::Credential() ;
        lease = new services::Lease() ;
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease ) ;
        o->getCredentialManager()->setValue( credential ) ;
        rgs = acs->getRegistryService() ;
        services::PropertyList* propertyList = new services::PropertyList;
        services::ServiceOffer* serviceOffer = new services::ServiceOffer;
        serviceOffer->properties = propertyList;
        property = new services::Property;
        property->name = "type";
        propertyValue = new services::PropertyValue;
        propertyValue->newmember("SessionService");
        property->value = propertyValue;
        propertyList->newmember(property);
        serviceOfferList = rgs->find( propertyList ) ;
        if ( serviceOfferList != NULL )
        {
          serviceOffer = serviceOfferList->getmember( 0 ) ;
          component = serviceOffer->member ;
          services::ISessionService* ses = component->getFacet <services::ISessionService> \
              ( "IDL:openbusidl/ss/ISessionService:1.0" ) ;
          scs::core::IComponent* c1 = new scs::core::IComponent( "membro1" ) ;
          scs::core::IComponent* c2 = new scs::core::IComponent( "membro2" ) ;
          class MySessionEventSink: public services::SessionEventSink {
            void push( services::SessionEvent* ev )
            {
              printf( "\nEvento %s valor %s recebido por %s\n\n", ev->type, ev->value, "IMPLEMENTAR..." ) ;
            }
            void disconnect()
            {
              printf( "\nAviso de desconexão para %s\n\n", "IMPLEMENTAR" ) ;
            }
          } ;
          MySessionEventSink* ev = new MySessionEventSink() ;
          c1->addFacet( "sink1", "IDL:openbusidl/ss/SessionEventSink:1.0", ev ) ;
          MySessionEventSink* ev2 = new MySessionEventSink() ;
          c2->addFacet( "sink2", "IDL:openbusidl/ss/SessionEventSink:1.0", ev2 ) ;
          char* mId ;
          services::ISession* s ;
          services::ISession* s2 ;
          ses->createSession( c1, s, mId ) ;
          services::MemberIdentifier mId2 = s->addMember( c2 ) ;
          services::SessionEvent* e = new services::SessionEvent ;
          e->type = "tipo1" ;
          e->value = "valor1" ;
          s->push(e) ;
          e->type = "tipo2" ;
          e->value = "valor2" ;
          s->push(e) ;
          s->disconnect() ;
          s2 = ses->getSession() ;
          services::SessionIdentifier sId  = s->getIdentifier() ;
          services::SessionIdentifier sId2 = s2->getIdentifier() ;
          TS_ASSERT_SAME_DATA( sId, sId2, strlen( sId2 ) ) ;
          s->getMembers() ;
          s->removeMember( mId ) ;
          s->removeMember( mId2 ) ;
          delete s ;
          delete s2 ;
          delete c1 ;
          delete c2 ;
          delete ses ;
      }
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

} ;

#endif

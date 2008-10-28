/*
* acs/ACSTestSuite.cpp
*/

#ifndef ACS_TESTSUITE_H
#define ACS_TESTSUITE_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>

#define BUFFER_SIZE 1024

using namespace openbus ;

class ACSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o ;
    services::IAccessControlService* acs ;
    services::Credential* credential ;
    services::Lease* lease ;
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
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testGetACS()
    {
      try {
        acs = o->getACS( OPENBUS_SERVER_HOST, OPENBUS_SERVER_PORT ) ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testLoginByPassword()
    {
      try {
        credential = new services::Credential() ;
        services::Credential* credential2 = new services::Credential() ;
        lease = new services::Lease() ;
        services::Lease* lease2 = new services::Lease() ;
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease ) ;
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential2, lease2 ) ;
        TS_ASSERT_SAME_DATA( credential->owner, OPENBUS_USERNAME, 6 ) ;
        TS_ASSERT_SAME_DATA( credential2->owner, OPENBUS_USERNAME, 6 ) ;
        TS_ASSERT( strcmp( credential2->identifier, credential->identifier ) ) ;
        o->getCredentialManager()->setValue( credential ) ;
        acs->logout( credential ) ;
        o->getCredentialManager()->setValue( credential2 ) ;
        acs->logout( credential2 ) ;
        o->getCredentialManager()->invalidate() ;
        TS_ASSERT(!acs->loginByPassword( "INVALID", "INVALID", credential, lease )) ;
        TS_ASSERT_SAME_DATA( credential->identifier, "", 0 ) ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testIsValid()
    {
      try {
        services::Credential* c = new services::Credential ;
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease ) ;
        o->getCredentialManager()->setValue( credential ) ;
        TS_ASSERT( acs->isValid( credential ) ) ;
        c->identifier = "123" ;
        c->owner = OPENBUS_USERNAME ;
        c->delegate = "";
        TS_ASSERT( !acs->isValid( c ) ) ;
        acs->logout( credential ) ;
        TS_ASSERT_THROWS_ANYTHING( acs->isValid( credential ) ) ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testGetRegistry()
    {
      try {
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease ) ;
        o->getCredentialManager()->setValue( credential ) ;
        acs->getRegistryService() ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testRenewLease()
    {
      try {
        services::Lease* leaseout = new services::Lease() ;
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease ) ;
        o->getCredentialManager()->setValue( credential ) ;
        TS_ASSERT( acs->renewLease( credential, leaseout ) ) ;
        TS_ASSERT_EQUALS( 30, (int) *leaseout ) ;
        services::Credential* s = new services::Credential ;
        s->identifier = "" ;
        s->owner = "" ;
        s->delegate = "";
        TS_ASSERT( !acs->renewLease( s, leaseout ) ) ;
        acs->logout( credential ) ;
        o->getCredentialManager()->invalidate() ;
      } catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testLogout()
    {
      acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease ) ;
      o->getCredentialManager()->setValue( credential ) ;
      TS_ASSERT( acs->logout( credential ) ) ;
      services::Credential* c = new services::Credential ;
      c->owner = OPENBUS_USERNAME ;
      c->identifier = "dadadsa" ;
      c->delegate = "";
      TS_ASSERT_THROWS_ANYTHING( acs->logout( c ) ) ;
    }

    void testObservers()
    {
      try {
        class credentialObserver: public services::ICredentialObserver {
          void credentialWasDeleted ( services::Credential* aCredential )
          {
            printf("\nChamando metodo de callback 'credentialWasDeleted'\n");
            printf( "  credential->owner=%s\n", aCredential->owner ) ;
            printf( "  credential->identifier=%s\n\n", aCredential->identifier ) ;
            printf( "  credential->delegate=%s\n\n", aCredential->delegate ) ;
          }
        } ;
        services::CredentialIdentifierList* list = new services::CredentialIdentifierList ;
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease ) ;
        o->getCredentialManager()->setValue( credential ) ;
        credentialObserver* co = new credentialObserver;
        list->newmember( credential->identifier ) ;
        acs->addObserver( co, list ) ;
        TS_ASSERT( acs->logout( credential ) ) ;
        delete co ;
      } catch ( const char * errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testObservers2()
    {
      try {
        class credentialObserver: public services::ICredentialObserver {
        } ;
        services::CredentialIdentifierList* list = new services::CredentialIdentifierList ;
        services::Credential* c = new services::Credential ;;
        acs->loginByPassword( OPENBUS_USERNAME, OPENBUS_PASSWORD, c, lease ) ;
        o->getCredentialManager()->setValue( c ) ;
        credentialObserver* co = new credentialObserver ;
        list->newmember( c->identifier ) ;
        const char* id = acs->addObserver( co, list ) ;
        TS_ASSERT( acs->addCredentialToObserver( id, c->identifier ) ) ;
        TS_ASSERT( acs->removeCredentialFromObserver( id, c->identifier ) ) ;
        TS_ASSERT( acs->removeObserver( id ) ) ;
        TS_ASSERT( !acs->removeObserver( id ) ) ;
        TS_ASSERT( acs->logout( c ) ) ;
        delete co ;
      } catch ( const char * errmsg ) {
        TS_FAIL( errmsg ) ;
      } /* try */
    }

    void testLoginByCertificate()
    {
      credential = new services::Credential() ;
      lease = new services::Lease() ;
      const char* certificate = "AccessControlService" ;
      const char* bytes = acs->getChallenge( certificate ) ;
      TS_ASSERT( acs->loginByCertificate( certificate, bytes, credential, lease ) ) ;
      delete bytes ;
      delete acs ;
    }
} ;

#endif

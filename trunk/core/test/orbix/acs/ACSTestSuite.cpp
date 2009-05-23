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
#include <services/AccessControlService.h>
#include <fstream>

using namespace openbus;

class ACSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* bus;
    services::AccessControlService* acs;
    openbusidl::acs::IAccessControlService* iacs;
    services::RegistryService* rgs;
    Credential* credential;
    Credential* credential2;
    Lease lease;
    Lease lease2;
    std::string OPENBUS_SERVER_HOST;
    unsigned short OPENBUS_SERVER_PORT;
    std::string OPENBUS_USERNAME;
    std::string OPENBUS_PASSWORD;

  public:
    ACSTestSuite() {
      try {
        std::string OPENBUS_HOME = getenv("OPENBUS_HOME");
        OPENBUS_HOME += "/core/test/orbix/config.txt";
        std::string temp;
        std::ifstream inFile;
        inFile.open(OPENBUS_HOME.c_str());
        if (!inFile) {
          temp = "N�o foi poss�vel carregar o arquivo " + OPENBUS_HOME + ".";
          TS_FAIL( temp );
        }
        while (inFile >> temp) {
          if (temp.compare("OPENBUS_SERVER_HOST") == 0) {
            inFile >> temp; // le o '='
            inFile >> OPENBUS_SERVER_HOST; // le o valor
          }
          if (temp.compare("OPENBUS_SERVER_PORT") == 0) {
            inFile >> temp;
            inFile >> OPENBUS_SERVER_PORT;
          }
          if (temp.compare("OPENBUS_USERNAME") == 0) {
            inFile >> temp;
            inFile >> OPENBUS_USERNAME;
          }
          if (temp.compare("OPENBUS_PASSWORD") == 0) {
            inFile >> temp;
            inFile >> OPENBUS_PASSWORD;
          }
        }
        inFile.close();
        bus = new Openbus(0, NULL, const_cast<char*>(OPENBUS_SERVER_HOST.c_str()), OPENBUS_SERVER_PORT);
        bus->init();
        credential2 = new Credential;
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    ~ACSTestSuite() {
      try {
        if ( NULL != bus ) {
          if (bus->disconnect())
            delete bus;
        }
        delete credential2;
        delete rgs;
        delete acs;
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    void setUP() {
    }

    void tearDown() {
    }

    void testConnect() {
      try {
        rgs = bus->connect( OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str() );
        TS_ASSERT( NULL != rgs );
        credential = bus->getCredential();
        lease = bus->getLease();
        TS_ASSERT( NULL != credential );
      }
      catch (openbus::COMMUNICATION_FAILURE& e) {
        TS_FAIL( "** Nao foi possivel se conectar ao barramento. **" );
      }
      catch (openbus::LOGIN_FAILURE& e) {
        TS_FAIL( "** Nao foi possivel se conectar ao barramento. Par usuario/senha inv�lido. **" );
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    void testGetACS() {
      try {
        acs = bus->getAccessControlService();
        TS_ASSERT( NULL != acs );
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      }
    }

    void testGetRegistryService() {
      try {
        delete rgs;
        rgs = acs->getRegistryService();
        TS_ASSERT( NULL != rgs );
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    void testGetStub() {
      try {
        iacs = acs->getStub();
        TS_ASSERT( NULL != iacs );
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg ) ;
      }
    }

    void testRenewLease() {
      try {
        TS_ASSERT( acs->renewLease( *credential, lease ) );
        TS_ASSERT_EQUALS( 30, lease );
        credential2->identifier = "";
        credential2->owner = "";
        credential2->delegate = "";
        TS_ASSERT( !acs->renewLease( *credential2, lease ) );
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    void testLogout() {
      iacs->loginByPassword( OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str(), credential2, lease2 );
      TS_ASSERT( acs->logout( *credential2 ) );
      credential2->owner = OPENBUS_USERNAME.c_str();
      credential2->identifier = "dadadsa";
      credential2->delegate = "";
      TS_ASSERT( ! acs->logout( *credential2 ) );
    }

    void testLoginByCertificate() {
      const char* certificate = "AccessControlService";
      openbusidl::OctetSeq* bytes = iacs->getChallenge( certificate );
      TS_ASSERT( iacs->loginByCertificate( certificate, *bytes, credential2, lease2 ) );
      delete bytes;
    }

    void testIsValid() {
      try {
        TS_ASSERT( iacs->isValid( *credential2 ) );
        credential2->identifier = "123";
        credential2->owner = OPENBUS_USERNAME.c_str();
        credential2->delegate = "";
        TS_ASSERT( !iacs->isValid( *credential2 ) );
        iacs->logout( *credential2 );
        TS_ASSERT( ! iacs->isValid( *credential2 ) );
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }
};

#endif

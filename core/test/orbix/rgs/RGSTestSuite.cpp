/*
* rgs/RGSTestSuite.cpp
*/

#ifndef RGS_TESTSUITE_H
#define RGS_TESTSUITE_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fstream>
#include <cxxtest/TestSuite.h>
#include <openbus.h>
#include <services/AccessControlService.h>
#include <scs/core/IComponentOrbix.h>

using namespace openbus;

class RGSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* bus;
    services::AccessControlService* acs;
    services::RegistryService* rgs;
    Credential* credential;
    Lease lease;
    char* registryIdentifier;
    char* registryIdentifier2;
    openbus::services::PropertyListHelper* propertyListHelper;
    openbus::services::PropertyListHelper* propertyListHelper2;
    scs::core::IComponentImpl* member;
    std::string OPENBUS_SERVER_HOST;
    unsigned short OPENBUS_SERVER_PORT;
    std::string OPENBUS_USERNAME;
    std::string OPENBUS_PASSWORD;

  public:
    RGSTestSuite() {
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
        credential = new Credential;
        rgs = bus->connect( OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str() );
        acs = bus->getAccessControlService();
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    ~RGSTestSuite() {
      try {
        if ( NULL != bus ) {
          if (bus->disconnect())
            delete bus;
        }
        delete propertyListHelper;
        delete propertyListHelper2;
        delete credential;
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

    void testGetRGS() {
      try {
        delete rgs;
        rgs = acs->getRegistryService();
        TS_ASSERT( NULL != rgs );
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testRegister() {
      try {
        scs::core::ComponentBuilder* componentBuilder = bus->getComponentBuilder();
        member = componentBuilder->createComponent("component", '1', '0', '0', "none");
        propertyListHelper = new openbus::services::PropertyListHelper();
        propertyListHelper->add("type", "type1");
        openbusidl::rs::ServiceOffer serviceOffer;
        serviceOffer.properties = propertyListHelper->getPropertyList();
        serviceOffer.member = member->_this();
        TS_ASSERT( rgs->Register(serviceOffer, registryIdentifier) );
        propertyListHelper2 = new openbus::services::PropertyListHelper();
        propertyListHelper2->add("type", "type2");
        serviceOffer.properties = propertyListHelper2->getPropertyList();
        serviceOffer.member = member->_this();
        TS_ASSERT( rgs->Register(serviceOffer, registryIdentifier2) );
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testFind() {
      openbusidl::rs::ServiceOfferList* serviceOfferList = rgs->find(propertyListHelper->getPropertyList());
      TS_ASSERT(serviceOfferList->length() == 1);
      delete serviceOfferList;
      serviceOfferList = rgs->find(propertyListHelper2->getPropertyList());
      TS_ASSERT(serviceOfferList->length() == 1);
      delete serviceOfferList;
    }
};

#endif

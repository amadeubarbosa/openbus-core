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
    Openbus* o;
    services::AccessControlService* acs;
    services::RegistryService* rgs;
    Credential* credential;
    Lease lease;
    char* RegistryIdentifier;
    openbusidl::rs::ServiceOfferList serviceOfferList;
    openbusidl::rs::Property* property;
    openbusidl::rs::PropertyList_var propertyList;
    openbusidl::rs::PropertyValue_var propertyValue;
    scs::core::IComponentImpl* member;
    std::string OPENBUS_SERVER_HOST;
    unsigned short OPENBUS_SERVER_PORT;
    std::string OPENBUS_USERNAME;
    std::string OPENBUS_PASSWORD;

  public:
    RGSTestSuite() {
      o = Openbus::getInstance();
      o->init(0, NULL);
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
        credential = new Credential;
        rgs = o->connect( OPENBUS_SERVER_HOST.c_str(), OPENBUS_SERVER_PORT, OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str() );
        acs = o->getAccessControlService();
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    ~RGSTestSuite() {
      try {
        if ( NULL != o ) {
          o->disconnect();
          o = NULL;
        }
        delete property;
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
        scs::core::ComponentBuilder* componentBuilder = o->getComponentBuilder();
        member = componentBuilder->createComponent("component", '1', '0', '0', "none", "facet", "", NULL);
        propertyList = new openbusidl::rs::PropertyList(1);
        propertyList->length(1);
        property = new openbusidl::rs::Property;
        property->name = "type";
        propertyValue = new openbusidl::rs::PropertyValue(3);
        propertyValue->length(3);
        propertyValue[0] = "type1";
        propertyValue[1] = "a";
        propertyValue[2] = "b";
        property->value = propertyValue;
        propertyList[0] = property;
        openbusidl::rs::ServiceOffer *serviceOffer = new openbusidl::rs::ServiceOffer;
        serviceOffer->properties = propertyList;
        serviceOffer->member = member;
        TS_ASSERT( rgs->Register(*serviceOffer, RegistryIdentifier) );
        delete serviceOffer;
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testRegister2() {
      try {
        propertyValue = new openbusidl::rs::PropertyValue(3);
        propertyValue->length(3);
        propertyValue[0] = "type2";
        propertyValue[1] = "c";
        propertyValue[2] = "d";
        property->value = propertyValue;
        TS_ASSERT( rgs->Register(propertyList, member, RegistryIdentifier) );
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testFind() {
      serviceOfferList = rgs->find(propertyList);
      TS_ASSERT(serviceOfferList->length() == 2);
      delete serviceOfferList;
      propertyValue = new openbusidl::rs::PropertyValue(3);
      propertyValue->length(3);
      propertyValue[0] = "type1";
      propertyValue[1] = "a";
      propertyValue[2] = "b";
      property->value = propertyValue;
      serviceOfferList = rgs->find(propertyList);
      TS_ASSERT(serviceOfferList->length == 1);
    }
};

#endif

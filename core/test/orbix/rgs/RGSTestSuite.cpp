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

using namespace openbus;

class RGSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* bus;
    openbusidl::acs::IAccessControlService* iAccessControlService;
    services::RegistryService* rgs;
    Credential* credential;
    Lease lease;
    char* registryIdentifier;
    char* registryIdentifier2;
    openbus::services::PropertyListHelper* propertyListHelper;
    openbus::services::PropertyListHelper* propertyListHelper2;
    scs::core::IComponent_var component;
    std::string OPENBUS_SERVER_HOST;
    unsigned short OPENBUS_SERVER_PORT;
    std::string OPENBUS_USERNAME;
    std::string OPENBUS_PASSWORD;
    scs::core::ComponentBuilder* componentBuilder;
    scs::core::ComponentContext* context;

    void fillComponentId(scs::core::ComponentId& id) {
      id.name = "RGSTestSuiteComponent";
      id.major_version = '1';
      id.minor_version = '0';
      id.patch_version = '0';
      id.platform_spec = "none";
    }

  public:
    RGSTestSuite() {
      try {
        std::string OPENBUS_HOME = getenv("OPENBUS_HOME");
        OPENBUS_HOME += "/core/test/orbix/config.txt";
        std::string temp;
        std::ifstream inFile;
        inFile.open(OPENBUS_HOME.c_str());
        if (!inFile) {
          temp = "Não foi possível carregar o arquivo " + OPENBUS_HOME + ".";
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
        bus = Openbus::getInstance();
        bus->init(
          0, 
          NULL, 
          const_cast<char*>(OPENBUS_SERVER_HOST.c_str()), 
          OPENBUS_SERVER_PORT);
        credential = new Credential;
        rgs = bus->connect(OPENBUS_USERNAME.c_str(), OPENBUS_PASSWORD.c_str());
        iAccessControlService = bus->getAccessControlService();
      }
      catch ( const char* errmsg ) {
        TS_FAIL( errmsg );
      }
    }

    ~RGSTestSuite() {
      try {
        delete context;
        if (bus) {
          if (bus->disconnect())
            delete bus;
        }
        delete propertyListHelper;
        delete propertyListHelper2;
        delete credential;
      }
      catch (const char* errmsg ) {
        TS_FAIL(errmsg);
      }
    }

    void setUP() {
    }

    void tearDown() {
    }

    void testGetRegisterService() {
      try {
        rgs = bus->getRegistryService();
        TS_ASSERT(rgs);
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testRegister() {
      try {
        componentBuilder = bus->getComponentBuilder();

        scs::core::ComponentId id;
        fillComponentId(id);

        std::list<scs::core::ExtendedFacetDescription> extFacets;
        context = componentBuilder->newComponent(extFacets, id);
        component = context->getIComponent();

        propertyListHelper = new openbus::services::PropertyListHelper();
        propertyListHelper->add("description", "blabla");

        openbusidl::rs::ServiceOffer serviceOffer;
        serviceOffer.properties = propertyListHelper->getPropertyList();
        serviceOffer.member = component;
        TS_ASSERT(rgs->Register(serviceOffer, registryIdentifier));

        propertyListHelper2 = new openbus::services::PropertyListHelper();
        serviceOffer.properties = propertyListHelper2->getPropertyList();
        serviceOffer.member = component;
        TS_ASSERT(rgs->Register(serviceOffer, registryIdentifier2));
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testFind() {
      openbus::services::FacetListHelper* facetListHelper = \
        new openbus::services::FacetListHelper();
      facetListHelper->add("IComponent");

      openbusidl::rs::ServiceOfferList* serviceOfferList = 
        rgs->find(facetListHelper->getFacetList());
      TS_ASSERT(serviceOfferList->length() == 2);
      delete serviceOfferList;
      delete facetListHelper;
    }

    void testFindByCriteria() {
      openbus::services::FacetListHelper* facetListHelper = \
        new openbus::services::FacetListHelper();
      facetListHelper->add("IComponent");

      openbusidl::rs::ServiceOfferList* serviceOfferList = \
        rgs->findByCriteria(
          facetListHelper->getFacetList(),
          propertyListHelper->getPropertyList());
      TS_ASSERT(serviceOfferList->length() == 1);
      delete serviceOfferList;
      delete facetListHelper;
    }

    void testUnregister() {
      TS_ASSERT(rgs->unregister(registryIdentifier));
      TS_ASSERT(rgs->unregister(registryIdentifier2));
      TS_ASSERT(!rgs->unregister((char*) "ID"));
    }
};

#endif


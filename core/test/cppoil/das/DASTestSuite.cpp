/*
* das/DASTestSuite.cpp
*/

#ifndef DAS_TESTSUITE_H
#define DAS_TESTSUITE_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>
#include <stubs/IDataService.h>

#define BUFFER_SIZE 1024

using namespace openbus;
using namespace dataService;

class DASTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o;
    services::IAccessControlService* acs;
    services::IRegistryService* rgs;
    services::ServiceOfferList* serviceOfferList;
    services::ServiceOffer* so;
    services::Property* property;
    services::PropertyList* propertyList;
    services::PropertyValue* propertyValue;
    scs::core::IComponent* member;
    common::CredentialManager* credentialManager;
    common::ClientInterceptor* clientInterceptor;
    services::Credential* credential;
    services::Lease* lease;
    char BUFFER[BUFFER_SIZE];
    char* OPENBUS_SERVER_HOST;
    char* OPENBUS_SERVER_PORT;
    char* OPENBUS_USERNAME;
    char* OPENBUS_PASSWORD;
    dataService::IDataService* ds;
  public:
    void setUP() {
    }

    void testConstructor()
    {
      try {
        o = Openbus::getInstance();
        credentialManager = new common::CredentialManager;
        clientInterceptor = new common::ClientInterceptor(credentialManager);
        o->setClientInterceptor(clientInterceptor);
        acs = o->getACS("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0");
        credential = new services::Credential;
        lease = new services::Lease;
        acs->loginByPassword("tester", "tester", credential, lease);
        credentialManager->setValue(credential);
        rgs = acs->getRegistryService();
        propertyList = new services::PropertyList;
        property = new services::Property;
        property->name = "facets";
        property->value = new services::PropertyValue;
        property->value->newmember("projectDataService");
        propertyList->newmember(property);
        serviceOfferList = rgs->find(propertyList);
        TS_ASSERT(serviceOfferList != NULL);
        so = serviceOfferList->getmember(0);
        member = so->member;
        member->loadidlfile("/home/rcosme/tecgraf/work/openbus/idlpath/data_service.idl");
        ds = member->getFacet <dataService::IDataService> ("IDL:openbusidl/ds/IDataService:1.0");
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      } /* try */
    }

    void testGetRoots()
    {
      DataList* dl = ds->getRoots();
      Data* data = dl->getmember(0);
      ds->getFacetInterfaces(data->key);
      dl = ds->getChildren(data->key);
      data = dl->getmember(0);
      ds->getFacetInterfaces(data->key);
    }

};

#endif

/*
** ProjectService/TestSuite.cpp
*/

#ifndef PS_TESTSUITE_H
#define PS_TESTSUITE_H

#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>
// #include <ftc.h>
#include "../IProjectService.h"

using namespace openbus;
using namespace std;

class RGSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o;
    services::IAccessControlService* acs;
    services::IRegistryService* rgs;
    common::CredentialManager* credentialManager;
    common::ClientInterceptor* clientInterceptor;
    services::Credential* credential;
    services::Lease* lease;
    char* RegistryIdentifier;
    services::ServiceOfferList* serviceOfferList;
    services::Property* property;
    services::PropertyList* propertyList;
    services::PropertyValue* propertyValue;
    services::ServiceOffer* so;
    scs::core::IComponent* member;
    dataService::IDataService* ds;
    projectService::IProject* projI;
    projectService::IProject* projII;
    projectService::IProject* projIII;

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
        member->loadidlfile("/home/rcosme/tecgraf/work/openbus/idlpath/project_service.idl");
        ds = member->getFacet <dataService::IDataService> ("IDL:openbusidl/ds/IDataService:1.0");
        dataService::DataKey* dataKey = new dataService::DataKey;
        dataKey->service_id = member->getComponentId();
        dataKey->actual_data_id = (char*) "openbus";
        scs::core::NameList* interfaces = ds->getFacetInterfaces(dataKey);
        char* interface = interfaces->getmember(0);
        projI = ds->getDataFacet <projectService::IProject> (dataKey, interface);
        projI->getFacetInterface();
        projI->getName();
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      } /* try */
    }

};

#endif

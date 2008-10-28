/*
* rgs/RGSTestSuite.cpp
*/

#ifndef RGS_TESTSUITE_H
#define RGS_TESTSUITE_H

#include <string.h>
#include <stdlib.h>
#include <cxxtest/TestSuite.h>
#include <openbus.h>
#include "hello.hpp"
int  tolua_hello_open (lua_State*);

#define BUFFER_SIZE 1024

using namespace openbus;

class RGSTestSuite: public CxxTest::TestSuite {
  private:
    Openbus* o;
    services::IAccessControlService* acs;
    services::IRegistryService* rgs;
    services::Credential* credential;
    services::Lease* lease;
    char* RegistryIdentifier;
    services::ServiceOfferList* serviceOfferList;
    services::Property* property;
    services::PropertyList* propertyList;
    services::PropertyValue* propertyValue;
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
        o = Openbus::getInstance();
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
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      } /* try */
    }

    void testGetRGS()
    {
      try {
        acs = o->getACS(OPENBUS_SERVER_HOST, OPENBUS_SERVER_PORT);
        credential = new services::Credential;
        lease = new services::Lease;
        acs->loginByPassword(OPENBUS_USERNAME, OPENBUS_PASSWORD, credential, lease);
        o->getCredentialManager()->setValue(credential);
        rgs = acs->getRegistryService();
        scs::core::IComponent* member = new scs::core::IComponent("scs::core::IComponent Mock");
        propertyList = new services::PropertyList;
        property = new services::Property;
        property->name = "type";
        services::PropertyValue p;
        propertyValue = new services::PropertyValue;
        propertyValue->newmember("type1");
        propertyValue->newmember("b");
        propertyValue->newmember("c");
        property->value = propertyValue;
        propertyList->newmember(property);
        services::ServiceOffer* serviceOffer = new services::ServiceOffer;
        serviceOffer->properties = propertyList;
        serviceOffer->member = member;
        rgs->Register(serviceOffer, RegistryIdentifier);
        propertyList = new services::PropertyList;
        property = new services::Property;
        property->name = "type";
        propertyValue = new services::PropertyValue;
        propertyValue->newmember("type1");
        property->value = propertyValue;
        propertyList->newmember(property);
        serviceOfferList = rgs->find(propertyList);
        TS_ASSERT(serviceOfferList != NULL);
        TS_ASSERT(rgs->unregister(RegistryIdentifier));
        delete member;
        delete serviceOfferList;
      } catch (const char* errmsg) {
        TS_FAIL(errmsg);
      }
    }

    void testFind()
    {
      scs::core::IComponent* member = new scs::core::IComponent("scs::core::IComponent Mock");
      services::PropertyList* propertyList = new services::PropertyList;
      services::ServiceOffer* serviceOffer = new services::ServiceOffer;
      serviceOffer->properties = propertyList;
      property = new services::Property;
      property->name = "type";
      propertyValue = new services::PropertyValue;
      propertyValue->newmember("Y");
      property->value = propertyValue;
      propertyList->newmember(property);
      serviceOffer->member = member;
      TS_ASSERT(rgs->Register(serviceOffer, RegistryIdentifier));
      TS_ASSERT(rgs->find(propertyList) != NULL);
      propertyList = new services::PropertyList;
      property = new services::Property;
      property->name = "type";
      propertyValue = new services::PropertyValue;
      propertyValue->newmember("X");
      property->value = propertyValue;
      propertyList->newmember(property);
      TS_ASSERT(rgs->find(propertyList) == NULL);
      TS_ASSERT(rgs->unregister(RegistryIdentifier));
      delete member;
    }

    void testUpdate()
    {
      scs::core::IComponent* member = new scs::core::IComponent("scs::core::IComponent Mock");
      services::PropertyList* propertyList = new services::PropertyList;
      services::ServiceOffer* serviceOffer = new services::ServiceOffer;
      serviceOffer->properties = propertyList;
      serviceOffer->member = member;
      TS_ASSERT(rgs->Register(serviceOffer, RegistryIdentifier));
      propertyList = new services::PropertyList;
      property = new services::Property;
      property->name = "type";
      propertyValue = new services::PropertyValue;
      propertyValue->newmember("X");
      property->value = propertyValue;
      propertyList->newmember(property);
      TS_ASSERT(rgs->find(propertyList) == NULL);
      propertyList = new services::PropertyList;
      property = new services::Property;
      property->name = "type";
      propertyValue = new services::PropertyValue;
      propertyValue->newmember("X");
      property->value = propertyValue;
      propertyList->newmember(property);
      TS_ASSERT(rgs->update(RegistryIdentifier, propertyList));
      propertyList = new services::PropertyList;
      property = new services::Property;
      property->name = "type";
      propertyValue = new services::PropertyValue;
      propertyValue->newmember("X");
      property->value = propertyValue;
      propertyList->newmember(property);
      TS_ASSERT(rgs->find(propertyList) != NULL);
      TS_ASSERT(rgs->unregister(RegistryIdentifier));
      delete member;
    }

    void testFacets()
    {
      tolua_hello_open(o->getLuaVM());
      hello* obj = new hello;
      scs::core::IComponent* member = new scs::core::IComponent("scs::core::IComponent");
      member->loadidl("interface hello { void say_hello(); };");
      member->addFacet("Faceta01", "IDL:hello:1.0", "hello", obj);
      member->addFacet("Faceta02", "IDL:hello:1.0", "hello", obj);
      services::PropertyList* propertyList = new services::PropertyList;
      property = new services::Property;
      property->name = "p1";
      propertyValue = new services::PropertyValue;
      propertyValue->newmember("b");
      property->value = propertyValue;
      propertyList->newmember(property);
      services::ServiceOffer* serviceOffer = new services::ServiceOffer;
      serviceOffer->properties = propertyList;
      serviceOffer->member = member;
      TS_ASSERT(rgs->Register(serviceOffer, RegistryIdentifier));
      propertyList = new services::PropertyList;
      property = new services::Property;
      property->name = "facets";
      propertyValue = new services::PropertyValue;
      propertyValue->newmember("Faceta01");
      property->value = propertyValue;
      propertyList->newmember(property);
      obj = member->getFacet <hello> ("IDL:hello:1.0");
      obj->say_hello();
      delete obj;
      TS_ASSERT(rgs->unregister(RegistryIdentifier));
      delete member;
      delete acs;
    }

};

#endif

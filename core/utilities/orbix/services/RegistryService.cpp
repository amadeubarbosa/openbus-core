/*
** RegistryService.cpp
*/

#include "RegistryService.h"

#ifdef VERBOSE
  #include <iostream>
#endif

#define VECTORSIZE 256

#ifdef VERBOSE
  #include "../openbus.h"
#endif

namespace openbus {
  namespace services {

    FacetListHelper::FacetListHelper() {
      facetList = new openbusidl::rs::FacetList();
      numElements = 0;
    }

    FacetListHelper::~FacetListHelper() {
    }

    void FacetListHelper::add(const char* facet) {
      facetList->length(numElements + 1);
      facetList[numElements] = facet;
      numElements++;
    }

    openbusidl::rs::FacetList_var FacetListHelper::getFacetList() {
      return facetList;
    }

    PropertyListHelper::PropertyListHelper() {
      propertyList = new openbusidl::rs::PropertyList();
      numElements = 0;
    }

    PropertyListHelper::~PropertyListHelper() {
    }

    void PropertyListHelper::add(
      const char* key,
      const char* value)
    {
      propertyList->length(numElements + 1);
      openbusidl::rs::Property_var property = new openbusidl::rs::Property;
      property->name = key;
      openbusidl::rs::PropertyValue_var propertyValue = \
        new openbusidl::rs::PropertyValue(1);
      propertyValue->length(1);
      propertyValue[0] = value;
      property->value = propertyValue;
      propertyList[numElements] = property;
      numElements++;
    }

    openbusidl::rs::PropertyList_var PropertyListHelper::getPropertyList() {
      return propertyList;
    }

    RegistryService::RegistryService(openbusidl::rs::IRegistryService* _rgs) {
    #ifdef VERBOSE
      Openbus::verbose->print("RegistryService::RegistryService() BEGIN");
      Openbus::verbose->indent();
    #endif
      rgs = _rgs;
    #ifdef VERBOSE
      stringstream msg;
      msg << "iRegistryService: " << rgs;
      Openbus::verbose->print(msg.str());
      Openbus::verbose->dedent("RegistryService::RegistryService() END");
    #endif
    }

    ServiceOfferList* RegistryService::find(FacetList facets) {
    #ifdef VERBOSE
      Openbus::verbose->print("RegistryService::find() BEGIN");
      Openbus::verbose->indent();
      stringstream msg;
      msg << "iRegistryService: " << rgs;
      Openbus::verbose->print(msg.str());
    #endif
      ServiceOfferList* serviceOfferList = rgs->find(facets);
    #ifdef VERBOSE
      Openbus::verbose->dedent("RegistryService::find() END");
    #endif
      return serviceOfferList;
    }

    ServiceOfferList* RegistryService::findByCriteria(
      FacetList facets, 
      PropertyList criteria) 
    {
    #ifdef VERBOSE
      Openbus::verbose->print("RegistryService::findByCriteria() BEGIN");
      Openbus::verbose->indent();
      stringstream msg;
      msg << "iRegistryService: " << rgs;
      Openbus::verbose->print(msg.str());
    #endif
      ServiceOfferList* serviceOfferList = rgs->findByCriteria(facets, criteria);
    #ifdef VERBOSE
      Openbus::verbose->dedent("RegistryService::findByCriteria() END");
    #endif
      return serviceOfferList;
    }

    bool RegistryService::Register(
      ServiceOffer serviceOffer,
      char*& registryId)
    {
    #ifdef VERBOSE
      Openbus::verbose->print("RegistryService::Register() BEGIN");
      Openbus::verbose->indent();
      stringstream msg;
      msg << "iRegistryService: " << rgs;
      Openbus::verbose->print(msg.str());
    #endif
      openbusidl::rs::RegistryIdentifier_var _registryId;
      bool returnValue = rgs->_cxx_register(serviceOffer, _registryId);
      registryId = _registryId._retn();
    #ifdef VERBOSE
      stringstream returnValueMsg;
      returnValueMsg << "returnValue = " << returnValue; 
      Openbus::verbose->print(returnValueMsg.str());
      stringstream registryIdMsg;
      registryIdMsg << "returnValue = " << registryId; 
      Openbus::verbose->print(registryIdMsg.str());
      Openbus::verbose->dedent("RegistryService::Register() END");
    #endif
      return returnValue;
    }

    bool RegistryService::unregister(char* registryId) {
    #ifdef VERBOSE
      Openbus::verbose->print("RegistryService::unregister() BEGIN");
      Openbus::verbose->indent();
      stringstream msg;
      msg << "iRegistryService: " << rgs;
      Openbus::verbose->print(msg.str());
      stringstream registryIdMsg;
      registryIdMsg << "registryId = " << registryId; 
      Openbus::verbose->print(registryIdMsg.str());
    #endif
      bool returnValue = rgs->unregister(registryId);
    #ifdef VERBOSE
      Openbus::verbose->dedent("RegistryService::unregister() END");
    #endif
      return returnValue;
    }
  }
}

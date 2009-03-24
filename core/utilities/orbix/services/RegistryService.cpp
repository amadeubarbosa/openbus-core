/*
** RegistryService.cpp
*/

#include "RegistryService.h"

#define VECTORSIZE 256

namespace openbus {
  namespace services {

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
      openbusidl::rs::PropertyValue_var propertyValue = new openbusidl::rs::PropertyValue(1);
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
      rgs = _rgs;
    }

    ServiceOfferList* RegistryService::find(PropertyList criteria) {
      return rgs->find(criteria);
    }

    bool RegistryService::Register(
      ServiceOffer serviceOffer,
      char* registryId)
    {
      return rgs->_cxx_register(serviceOffer, registryId);
    }

    bool RegistryService::unregister(char* registryId) {
      return rgs->unregister(registryId);
    }
  }
}

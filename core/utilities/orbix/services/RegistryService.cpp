/*
** RegistryService.cpp
*/

#include "RegistryService.h"

#ifdef VERBOSE
  #include <iostream>
#endif

#define VECTORSIZE 256

#ifdef VERBOSE
  using namespace std;
#endif

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
      rgs = _rgs;
    }

    ServiceOfferList* RegistryService::find(PropertyList criteria) {
    #ifdef VERBOSE
      cout << "[RegistryService::find() BEGIN]" << endl;
    #endif
      ServiceOfferList* serviceOfferList = rgs->find(criteria);
    #ifdef VERBOSE
      cout << "[RegistryService::find() END]" << endl;
    #endif
      return serviceOfferList;
    }

    bool RegistryService::Register(
      ServiceOffer serviceOffer,
      char*& registryId)
    {
    #ifdef VERBOSE
      cout << "[RegistryService::Register() BEGIN]" << endl;
    #endif
      openbusidl::rs::RegistryIdentifier_var _registryId;
      bool returnValue = rgs->_cxx_register(serviceOffer, _registryId);
      registryId = _registryId._retn();
    #ifdef VERBOSE
      cout << "\treturnValue = " << returnValue << endl;
      cout << "\tregistryId = (" << registryId << ")" << endl;
      cout << "[RegistryService::Register() END]" << endl;
    #endif
      return returnValue;
    }

    bool RegistryService::unregister(char* registryId) {
    #ifdef VERBOSE
      cout << "[RegistryService::unregister() BEGIN]" << endl;
      cout << "\tregistryId = (" << registryId << ")" << endl;
    #endif
      bool returnValue = rgs->unregister(registryId);
    #ifdef VERBOSE
      cout << "[RegistryService::unregister() END]" << endl;
    #endif
      return returnValue;
    }
  }
}

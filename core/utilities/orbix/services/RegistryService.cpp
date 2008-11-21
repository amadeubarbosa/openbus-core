/*
** RegistryService.cpp
*/

#include "RegistryService.h"

#define VECTORSIZE 256

namespace openbus {
  namespace services {
    RegistryService::RegistryService(openbusidl::rs::IRegistryService* _rgs) {
      rgs = _rgs;
    }

    openbusidl::rs::ServiceOfferList* RegistryService::find(openbusidl::rs::PropertyList criteria) {
      return rgs->find(criteria);
    }

    void RegistryService::Register(openbusidl::rs::ServiceOffer serviceOffer, char* registryId) {
      rgs->_cxx_register(serviceOffer, registryId);
    }

    void RegistryService::Register(PropertyList propertyList, scs::core::IComponent* iComponent, char* registryId) {
/*  char* propertyList[3] = {"facet", "IHello", 0};
  registryService->Register(propertyList, IComponent->_this(), registryId);*/
      openbusidl::rs::ServiceOffer serviceOffer;
      openbusidl::rs::PropertyList_var pList = new openbusidl::rs::PropertyList(VECTORSIZE);
      pList->length(1);

      CORBA::ULong idx;
      for (idx = 0;propertyList[idx] != 0;) {
        std::cout << idx << std::endl << std::endl << std::endl;
        openbusidl::rs::Property_var property = new openbusidl::rs::Property;
        property->name = propertyList[idx];
        openbusidl::rs::PropertyValue_var propertyValue = new openbusidl::rs::PropertyValue(VECTORSIZE);
        propertyValue->length(1);
        propertyValue[0] = propertyList[idx+1];
        property->value = propertyValue;

        pList[idx] = property;
        idx++;
        idx++;
      }

      serviceOffer.member = iComponent;
      serviceOffer.properties = pList;

      rgs->_cxx_register(serviceOffer, registryId);
    }

  }
}

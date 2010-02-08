/**
* \file Helper.cpp
*
* \brief Facilitador para a utilização de estruturas
* complexas.
*
*/

#include "Helper.h"

namespace openbus {
  namespace util {

    FacetListHelper::FacetListHelper() {
      facetList = new registry_service::FacetList();
      numElements = 0;
    }

    FacetListHelper::~FacetListHelper() {
    }

    void FacetListHelper::add(const char* facet) {
      facetList->length(numElements + 1);
      facetList[numElements] = facet;
      numElements++;
    }

    registry_service::FacetList_var FacetListHelper::getFacetList() {
      return facetList;
    }

    PropertyListHelper::PropertyListHelper() {
      propertyList = new registry_service::PropertyList();
      numElements = 0;
    }

    PropertyListHelper::~PropertyListHelper() {
    }

    void PropertyListHelper::add(
      const char* key,
      const char* value)
    {
      propertyList->length(numElements + 1);
      registry_service::Property_var property = new registry_service::Property;
      property->name = key;
      registry_service::PropertyValue_var propertyValue = \
        new registry_service::PropertyValue(1);
      propertyValue->length(1);
      propertyValue[(CORBA::ULong) 0] = value;
      property->value = propertyValue;
      propertyList[numElements] = property;
      numElements++;
    }

    registry_service::PropertyList_var PropertyListHelper::getPropertyList() {
      return propertyList;
    }
  }
}


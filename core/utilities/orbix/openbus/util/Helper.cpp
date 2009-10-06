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
  }
}


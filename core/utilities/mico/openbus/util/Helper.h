/**
* \file Helper.h
*
* \brief Facilitador para a utilização de estruturas
* complexas.
*
*/

#ifndef HELPER_H_
#define HELPER_H_

#include "../../stubs/registry_service.h"

/**
* \brief openbus
*/
namespace openbus {

/**
* \brief Utilitários para a programação.
*/
  namespace util {

    typedef openbusidl::rs::FacetList FacetList;
    typedef openbusidl::rs::PropertyList PropertyList;
    typedef openbusidl::rs::ServiceOffer ServiceOffer;
    typedef openbusidl::rs::ServiceOfferList ServiceOfferList;
    typedef openbusidl::rs::ServiceOfferList_var ServiceOfferList_var;

  /**
  * \brief Auxilia na construção de uma lista de facetas.
  */
    class FacetListHelper {
      private:
        openbusidl::rs::FacetList_var facetList;
        CORBA::ULong numElements;
      public:
        FacetListHelper();
        ~FacetListHelper();
        void add(const char* facet);
        openbusidl::rs::FacetList_var getFacetList();
    };

  /**
  * \brief Auxilia na construção de uma lista de propriedades.
  */
    class PropertyListHelper {
      private:
        openbusidl::rs::PropertyList_var propertyList;
        CORBA::ULong numElements;
      public:
        PropertyListHelper();
        ~PropertyListHelper();
        void add(
          const char* key,
          const char* value);
        openbusidl::rs::PropertyList_var getPropertyList();
    };
  }
}

#endif 


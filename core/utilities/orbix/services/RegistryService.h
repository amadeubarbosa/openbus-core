/*
** RegistryService.h
*/

#ifndef REGISTRYSERVICE_H_
#define REGISTRYSERVICE_H_

#include "../stubs/scs.hh"
#include "../stubs/registry_service.hh"

namespace openbus {
  namespace services {
    typedef char** PropertyList;

    class RegistryService {
      private:
        openbusidl::rs::IRegistryService* rgs;
      public:
        RegistryService(openbusidl::rs::IRegistryService* _rgs);
        openbusidl::rs::ServiceOfferList* find(openbusidl::rs::PropertyList criteria);
        void Register(openbusidl::rs::ServiceOffer serviceOffer, char* registryId);
        void Register(PropertyList propertyList, scs::core::IComponent* iComponent, char* registryId);
    };
  }
}

#endif

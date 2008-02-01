/*
* oil/services/IRegistryService.h
*/

#ifndef IREGISTRY_SERVICE_H_
#define IREGISTRY_SERVICE_H_

#include "../openbus.h"

namespace openbus {
  namespace services {

    typedef luaidl::cpp::sequence<const char> PropertyValue ;

    struct Property {
        String name ;
        PropertyValue* value ;
    } ;

    typedef luaidl::cpp::sequence<Property> PropertyList ;

    struct ServiceOffer {
        String type ;
        String description ;
        PropertyList* properties ;
        scs::core::IComponent* member ;
    } ;

    typedef luaidl::cpp::sequence<ServiceOffer> ServiceOfferList ;

    typedef Identifier RegistryIdentifier ;

    class IRegistryService {
      private:
        IRegistryService( String reference, String interface ) ;
      public:
        ~IRegistryService( void ) ;
        IRegistryService( void ) ;
        bool Register( ServiceOffer* aServiceOffer, char*& outIdentifier ) ;
        bool unregister( RegistryIdentifier identifier ) ;
        bool update( RegistryIdentifier identifier, PropertyList* newProperties ) ;
        ServiceOfferList* find( String type, PropertyList* criteria ) ;
        friend class openbus::Openbus ;
    } ;
  }
}

#endif

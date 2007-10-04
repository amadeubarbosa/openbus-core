/*
* scs/core/IComponent.h
*/

#ifndef ICOMPONENT_H_
#define ICOMPONENT_H_

#include "../../openbus.h"

namespace scs {
  namespace core {

    class IComponent {
        void _getFacet ( void* ptr, openbus::String facet_interface ) ;
      public:
        IComponent( void ) ;
        IComponent( openbus::String name ) ;
        ~IComponent( void ) ;

        void  addFacet ( openbus::String name, openbus::String interface_name, \
                char* constructor_name, void * facet_servant) ;

        template <class T>
        T* getFacet ( openbus::String facet_interface )
        {
          void* ptr = (void*) new T ;
          _getFacet( ptr, facet_interface ) ;
          return ( T* ) ptr ;
        }

        friend class openbus::services::IRegistryService ;
    } ;

    typedef luaidl::cpp::sequence<IComponent> IComponentSeq ;
  }
}

#endif

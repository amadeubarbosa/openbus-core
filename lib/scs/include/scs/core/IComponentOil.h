/*
** scs/core/IComponentOil.h
*/

#ifndef ICOMPONENT_H_
#define ICOMPONENT_H_

#include <lua.hpp>

#include "luaidl/cpp/types.h"

namespace scs {
  namespace core {

    class IComponent {
        void _getFacet ( void* ptr, const char* facet_interface ) ;
        static lua_State* LuaVM ;
      public:
        IComponent() ;
        IComponent( const char* name ) ;
        ~IComponent() ;

        static void setLuaVM( lua_State* L ) ;
        void  addFacet ( const char* name, const char* interface_name, void * facet_servant) ;
      /* ToLua Support */
        void  addFacet ( const char* name, const char* interface_name, \
                char* constructor_name, void * facet_servant) ;
        void loadidl( const char* idl ) ;
        void loadidlfile( const char* idlfilename ) ;
        template <class T>
        T* getFacet ( const char* facet_interface )
        {
          void* ptr = (void*) new T ;
          _getFacet( ptr, facet_interface ) ;
          return ( T* ) ptr ;
        }

//        friend class openbus::services::IRegistryService ;
    } ;

    typedef luaidl::cpp::sequence<IComponent> IComponentSeq ;
  }
}

#endif

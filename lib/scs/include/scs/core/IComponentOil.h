/*
** scs/core/IComponentOil.h
*/

#ifndef ICOMPONENT_H_
#define ICOMPONENT_H_

#include <lua.hpp>

#include "luaidl/cpp/types.h"

namespace scs {
  namespace core {
    struct ComponentId {
      char* name;
      char major_version;
      char minor_version;
      char patch_version;
      char* platform_spec;
    };

    typedef luaidl::cpp::sequence<char> NameList;

    class IComponent {
        void _getFacet (void* ptr, const char* facet_interface);
        static lua_State* LuaVM;
      public:
        IComponent(const char* name, char major_version, char minor_version, char patch_version, \
            const char* platform_spec);
        ~IComponent();

        static void setLuaVM(lua_State* L);
        void  addFacet (const char* name, const char* interface_name, void* facet_servant);
      /* ToLua Support */
        void  addFacet (const char* name, const char* interface_name, \
                char* constructor_name, void* facet_servant);
        void loadidl(const char* idl);
        void loadidlfile(const char* idlfilename);
        template <class T>
        T* getFacet (const char* facet_interface)
        {
          void* ptr = (void*) new T;
          _getFacet(ptr, facet_interface);
          return (T*) ptr;
        }
        ComponentId* getComponentId();
    };

    typedef luaidl::cpp::sequence<IComponent> IComponentSeq;
  }
}

#endif

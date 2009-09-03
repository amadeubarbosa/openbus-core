/*
** ComponentBuilderOil.h
*/

#ifndef COMPONENTBUILDEROIL_H_
#define COMPONENTBUILDEROIL_H_

#include "IComponentOil.h"

namespace scs {
  namespace core {
    class ComponentBuilder {
      private:
        static lua_State* LuaVM;
      public:
        ComponentBuilder();
        ~ComponentBuilder();
        void setLuaVM(lua_State* L);
        IComponent* createComponent(const char* name, char major_version, \
            char minor_version, char patch_version, const char* platform_spec, \
            const char* facet_name, const char* interface_name, char* constructor_name, void* obj);
        void loadIDLFile(const char* idlfilename);
    };
  }
}

#endif
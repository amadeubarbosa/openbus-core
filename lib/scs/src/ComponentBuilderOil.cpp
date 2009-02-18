/*
** ComponentBuilderOil.cpp
*/

#include <scs/core/ComponentBuilderOil.h>

#include <lua.hpp>

namespace scs {
  namespace core {
    lua_State* ComponentBuilder::LuaVM = 0;

    ComponentBuilder::ComponentBuilder() {
      /* empty */
    }

    ComponentBuilder::~ComponentBuilder() {
      /* empty */
    }

    void ComponentBuilder::setLuaVM(lua_State* L) {
      LuaVM = L;
    }

    IComponent* ComponentBuilder::createComponent(const char* name, char major_version, \
        char minor_version, char patch_version, const char* platform_spec, \
        const char* facet_name, const char* interface_name, char* constructor_name, void* obj)
    {
      IComponent* iComponent = new IComponent(name, major_version, minor_version, patch_version, platform_spec);
      iComponent->addFacet(facet_name, interface_name, constructor_name, obj);
      return iComponent;
    }

    void ComponentBuilder::loadIDLFile(const char* idlfilename)
    {
    #if VERBOSE
      printf("[ComponentBuilder::loadIDLFile() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando proxy para IComponent]\n");
    #endif
      lua_getglobal(LuaVM, "orb");
      lua_getfield(LuaVM, -1, "loadidlfile");
      lua_insert(LuaVM, -2);
    #if VERBOSE
      printf("\t[metodo loadidlfile empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushstring(LuaVM, idlfilename);
    #if VERBOSE
      printf("\t[idlfilename=%s empilhado]\n", idlfilename);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      if (lua_pcall(LuaVM, 2, 0, 0) != 0) {
      #if VERBOSE
        printf("\t[ERRO ao realizar pcall do metodo]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename(LuaVM, lua_type(LuaVM, -1)));
      #endif
        const char * returnValue;
        lua_getglobal(LuaVM, "tostring");
        lua_insert(LuaVM, -2);
        lua_pcall(LuaVM, 1, 1, 0);
        returnValue = lua_tostring(LuaVM, -1);
        lua_pop(LuaVM, 1);
      #if VERBOSE
        printf("\t[lancando excecao %s]\nname", returnValue);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[ComponentBuilder::loadIDLFile FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
      #if VERBOSE
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[ComponentBuilder::loadIDLFile FIM]\n\n");
      #endif
    }

  }
}

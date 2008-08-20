/*
** IComponentOil.cpp
*/

#include <iostream>

#include <scs/core/IComponentOil.h>
#include <lua.hpp>
extern "C" {
  #include <tolua.h>
}

namespace scs {
  namespace core {

    lua_State* IComponent::LuaVM = 0;

  /* ??? */
    IComponent::IComponent ()
    {
    #if VERBOSE
      printf("[IComponent::IComponent() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
    #if VERBOSE
      printf("\t[Construindo objeto IComponent]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getglobal(LuaVM, "IComponent");
      lua_pushstring(LuaVM, "IDL:scs/core/IComponent:1.0");
    #if VERBOSE
      printf("\t[parametro name=%s empilhado]\n", "IDL:scs/core/IComponent:1.0");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushnumber(LuaVM, 1);
    #if VERBOSE
      printf("\t[parametro 1 empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      if (lua_pcall(LuaVM, 2, 1, 0) != 0) {
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
        printf("\t[lancando excecao]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::IComponent() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
    #if VERBOSE
      printf("\t[Chamando orb:newservant]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getglobal(LuaVM, "orb");
      lua_getfield( LuaVM, -1, "newservant" ) ;
      lua_insert(LuaVM, -3);
      lua_insert(LuaVM, -2);
    #if VERBOSE
      printf("\t[parametro IComponent empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushnil(LuaVM);
      lua_pushstring(LuaVM, "IDL:scs/core/IComponent:1.0");
    #if VERBOSE
      printf("\t[parametro IDL:scs/core/IComponent:1.0 empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      if (lua_pcall(LuaVM, 4, 1, 0) != 0) {
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
        printf("\t[lancando excecao]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::IComponent() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer(LuaVM, -1);
    #endif
      lua_pushlightuserdata(LuaVM, this);
      lua_insert(LuaVM, -2);
      lua_settable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[IComponent Lua:%p C:%p]\n", ptr, this);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[IComponent::IComponent() FIM]\n\n");
    #endif
    }

    IComponent::IComponent (const char* name)
    {
    #if VERBOSE
      printf("[IComponent::IComponent() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
    #if VERBOSE
      printf("\t[Construindo objeto IComponent]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getglobal(LuaVM, "IComponent");
      lua_pushstring(LuaVM, name);
    #if VERBOSE
      printf("\t[parametro name=%s empilhado]\n", name);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushnumber(LuaVM, 1);
    #if VERBOSE
      printf("\t[parametro 1 empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      if (lua_pcall(LuaVM, 2, 1, 0) != 0) {
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
        printf("\t[lancando excecao]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::IComponent() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
    #if VERBOSE
      printf("\t[Chamando orb:newservant]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getglobal(LuaVM, "orb");
      lua_getfield( LuaVM, -1, "newservant" ) ;
      lua_insert(LuaVM, -3);
      lua_insert(LuaVM, -2);
    #if VERBOSE
      printf("\t[parametro IComponent empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushnil(LuaVM);
      lua_pushstring(LuaVM, "IDL:scs/core/IComponent:1.0");
    #if VERBOSE
      printf("\t[parametro IDL:scs/core/IComponent:1.0 empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      if (lua_pcall(LuaVM, 4, 1, 0) != 0) {
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
        printf("\t[lancando excecao]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::IComponent() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer(LuaVM, -1);
    #endif
      lua_pushlightuserdata(LuaVM, this);
      lua_insert(LuaVM, -2);
      lua_settable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[IComponent Lua:%p C:%p]\n", ptr, this);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[IComponent::IComponent() FIM]\n\n");
    #endif
    }

    IComponent::~IComponent ()
    {
    #if VERBOSE
      printf("[Destruindo objeto IComponent (%p)...]\n", this);
      lua_pushlightuserdata(LuaVM, this);
      lua_gettable(LuaVM, LUA_REGISTRYINDEX);
      printf("[Liberando referencia Lua:%p]\n", lua_topointer(LuaVM, -1));
      lua_pop(LuaVM, 1);
    #endif
    lua_pushlightuserdata(LuaVM, this);
    lua_pushnil(LuaVM);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("[Objeto IComponent(%p) destruido!]\n\n", this);
    #endif
    }

    void  IComponent::addFacet (const char* name, const char* interface_name, void * facet_servant)
    {
    #if VERBOSE
      printf("[IComponent::addFacet() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando proxy para IComponent]\n");
    #endif
      lua_pushlightuserdata(LuaVM, this);
      lua_gettable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[IComponent Lua:%p C:%p]\n", lua_topointer(LuaVM, -1), this);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getfield(LuaVM, -1, "addFacet");
      lua_insert(LuaVM, -2);
    #if VERBOSE
      printf("\t[metodo addFacet empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushstring(LuaVM, name);
    #if VERBOSE
      printf("\t[name=%s empilhado]\n", name);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushstring(LuaVM, interface_name);
    #if VERBOSE
      printf("\t[interface_name=%s empilhado]\n", interface_name);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushlightuserdata(LuaVM, facet_servant);
      lua_gettable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[facet_servant(%p) empilhado]\n", lua_topointer(LuaVM, -1));
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      if (lua_pcall(LuaVM, 4, 1, 0) != 0) {
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
        printf("[IComponent::addFacet() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
      lua_pop(LuaVM, 1);
      #if VERBOSE
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::addFacet() FIM]\n\n");
      #endif
    }

    void IComponent::addFacet (const char* name, const char* interface_name, \
            char* constructor_name, void* facet_servant)
    {
    #if VERBOSE
      printf("[IComponent::addFacet() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando proxy para IComponent]\n");
    #endif
      lua_pushlightuserdata(LuaVM, this);
      lua_gettable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[IComponent Lua:%p C:%p]\n", lua_topointer(LuaVM, -1), this);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getfield(LuaVM, -1, "addFacet");
      lua_insert(LuaVM, -2);
    #if VERBOSE
      printf("\t[metodo addFacet empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushstring(LuaVM, name);
    #if VERBOSE
      printf("\t[name=%s empilhado]\n", name);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_pushstring(LuaVM, interface_name);
    #if VERBOSE
      printf("\t[interface_name=%s empilhado]\n", interface_name);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      tolua_pushusertype(LuaVM, facet_servant, constructor_name);
    #if VERBOSE
      printf("\t[facet_servant(%p) empilhado]\n", lua_topointer(LuaVM, -1));
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      if (lua_pcall(LuaVM, 4, 1, 0) != 0) {
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
        printf("[IComponent::addFacet() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
      lua_pop(LuaVM, 1);
      #if VERBOSE
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::addFacet() FIM]\n\n");
      #endif
    }

    void IComponent::loadidl(const char* idl)
    {
    #if VERBOSE
      printf("[IComponent::loadidl() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando proxy para IComponent]\n");
    #endif
      lua_getglobal(LuaVM, "orb");
      lua_getfield(LuaVM, -1, "loadidl");
      lua_remove(LuaVM, 1);
    #if VERBOSE
      printf("\t[metodo loadidl empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getglobal(LuaVM, "orb");
      lua_pushstring(LuaVM, idl);
    #if VERBOSE
      printf("\t[idl=%s empilhado]\n", idl);
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
        printf("[IComponent::loadidl() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
      #if VERBOSE
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::loadidl() FIM]\n\n");
      #endif
    }

    void IComponent::loadidlfile(const char* idlfilename)
    {
    #if VERBOSE
      printf("[IComponent::loadidlfile() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando proxy para IComponent]\n");
    #endif
      lua_getglobal(LuaVM, "orb");
      lua_getfield(LuaVM, -1, "loadidlfile");
      lua_remove(LuaVM, 1);
      lua_getglobal(LuaVM, "orb");
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
        printf("[IComponent::loadidlfile() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
      #if VERBOSE
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::loadidlfile() FIM]\n\n");
      #endif
    }

    void IComponent::_getFacet (void* ptr, const char* facet_interface)
    {
    #if VERBOSE
      printf("[IComponent::getFacet() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando proxy para IComponent]\n");
    #endif
      lua_getglobal(LuaVM, "invoke");
      lua_pushlightuserdata(LuaVM, this);
      lua_gettable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[IComponent Lua:%p C:%p]\n", \
        lua_topointer(LuaVM, -1), this);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getfield(LuaVM, -1, "getFacet");
    #if VERBOSE
      printf("\t[metodo getFacet empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename(LuaVM, lua_type(LuaVM, -1)));
    #endif
      lua_insert(LuaVM, -2);
      lua_pushstring(LuaVM, facet_interface);
    #if VERBOSE
      printf("\t[facet_interface=%s empilhado]\n", facet_interface);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename(LuaVM, lua_type(LuaVM, -1)));
    #endif
      if (lua_pcall(LuaVM, 3, 1, 0) != 0) {
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
        printf("\t[lancando excecao %s]\n", returnValue);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::getFacet() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
      lua_getglobal(LuaVM, "orb");
      lua_getfield(LuaVM, -1, "narrow");
      lua_pushvalue(LuaVM, -3);
      lua_getglobal(LuaVM, "orb");
      lua_pushstring(LuaVM, facet_interface);
      lua_pcall(LuaVM, 3, 1, 0);
    #if VERBOSE
      const void* luaRef = lua_topointer(LuaVM, -1);
    #endif
      lua_pushlightuserdata(LuaVM, ptr);
      lua_insert(LuaVM, -2);
      lua_settable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[OBJ Lua:%p C:%p]\n", luaRef, ptr);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename(LuaVM, lua_type(LuaVM, -1)));
    #endif
      lua_pop(LuaVM, 2);
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[IComponent::getFacet() FIM]\n\n");
    #endif
    }

    ComponentId* IComponent::getComponentId() {
      ComponentId* returnValue;
      size_t size;
    #if VERBOSE
      printf("[IComponent::getComponentId() COMECO]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Carregando proxy para IComponent]\n");
    #endif
      lua_getglobal(LuaVM, "invoke");
      lua_pushlightuserdata(LuaVM, this);
      lua_gettable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[IComponent Lua:%p C:%p]\n", \
        lua_topointer(LuaVM, -1), this);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
      lua_getfield(LuaVM, -1, "getComponentId");
    #if VERBOSE
      printf("\t[metodo getComponentId empilhado]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename(LuaVM, lua_type(LuaVM, -1)));
    #endif
      lua_insert(LuaVM, -2);
      if (lua_pcall(LuaVM, 2, 1, 0) != 0) {
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
        printf("\t[lancando excecao %s]\n", returnValue);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("[IComponent::getComponentId() FIM]\n\n");
      #endif
        throw returnValue;
      } /* if */
      returnValue = new ComponentId;
    #if VERBOSE
      printf("\t[gerando valor de retorno do tipo ComponentId*]\n");
      printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
    #endif

      lua_getfield(LuaVM, -1, "name");
      const char * luastring = lua_tolstring(LuaVM, -1, &size);
      returnValue->name = new char[ size + 1 ];
      memcpy(returnValue->name, luastring, size);
      returnValue->name[ size ] = '\0';
    #if VERBOSE
      printf("\t[componentId->name: %s]\n", returnValue->name);
      printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
    #endif
      lua_pop(LuaVM, 1);

      lua_getfield(LuaVM, -1, "version");
      returnValue->version = (unsigned long) lua_tonumber(LuaVM, -1);
    #if VERBOSE
      printf("\t[componentId->->version: %lu]\n", returnValue->version);
      printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
    #endif
      lua_pop(LuaVM, 2);
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[IComponent::getComponentId() FIM]\n\n");
    #endif
      return returnValue;
    }

    void IComponent::setLuaVM(lua_State* L) {
      LuaVM = L;
    }
  }
}

/*
* scs/core/IComponent.cpp
*/

#include <scs/core/IComponent.h>
#include <lua.hpp>
#include <tolua.h>

namespace scs {
  namespace core {

  using namespace openbus ;

  /* ??? */
    IComponent::IComponent ()
    {
    #if VERBOSE
      printf( "[IComponent::IComponent() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "  [Construindo objeto IComponent]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( openbus::Openbus::LuaVM, "IComponent" ) ;
      lua_pushstring( openbus::Openbus::LuaVM, "IDL:scs/core/IComponent:1.0" ) ;
    #if VERBOSE
      printf( "  [parametro name=%s empilhado]\n", "IDL:scs/core/IComponent:1.0" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushnumber( openbus::Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [parametro 1 empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( openbus::Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( openbus::Openbus::LuaVM, "tostring" ) ;
        lua_insert( openbus::Openbus::LuaVM, -2 ) ;
        lua_pcall( openbus::Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( openbus::Openbus::LuaVM, -1 ) ;
        lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      printf( "  [Chamando oil.newobject]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( openbus::Openbus::LuaVM, "oil" ) ;
      lua_pushstring( openbus::Openbus::LuaVM, "newobject" ) ;
      lua_gettable( openbus::Openbus::LuaVM, -2 ) ;
      lua_remove( openbus::Openbus::LuaVM, -2 ) ;
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [parametro IComponent empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( openbus::Openbus::LuaVM, "IDL:scs/core/IComponent:1.0") ;
    #if VERBOSE
      printf( "  [parametro IDL:scs/core/IComponent:1.0 empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( openbus::Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( openbus::Openbus::LuaVM, "tostring" ) ;
        lua_insert( openbus::Openbus::LuaVM, -2 ) ;
        lua_pcall( openbus::Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( openbus::Openbus::LuaVM, -1 ) ;
        lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( openbus::Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( openbus::Openbus::LuaVM, this ) ;
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
      lua_settable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IComponent Lua:%p C:%p]\n", ptr, this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "[IComponent::IComponent() FIM]\n\n" ) ;
    #endif
    }

    IComponent::IComponent ( openbus::String name )
    {
    #if VERBOSE
      printf( "[IComponent::IComponent() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "  [Construindo objeto IComponent]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( openbus::Openbus::LuaVM, "IComponent" ) ;
      lua_pushstring( openbus::Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "  [parametro name=%s empilhado]\n", name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushnumber( openbus::Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [parametro 1 empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( openbus::Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( openbus::Openbus::LuaVM, "tostring" ) ;
        lua_insert( openbus::Openbus::LuaVM, -2 ) ;
        lua_pcall( openbus::Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( openbus::Openbus::LuaVM, -1 ) ;
        lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      printf( "  [Chamando oil.newobject]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( openbus::Openbus::LuaVM, "oil" ) ;
      lua_pushstring( openbus::Openbus::LuaVM, "newobject" ) ;
      lua_gettable( openbus::Openbus::LuaVM, -2 ) ;
      lua_remove( openbus::Openbus::LuaVM, -2 ) ;
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [parametro IComponent empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( openbus::Openbus::LuaVM, "IDL:scs/core/IComponent:1.0") ;
    #if VERBOSE
      printf( "  [parametro IDL:scs/core/IComponent:1.0 empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( openbus::Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( openbus::Openbus::LuaVM, "tostring" ) ;
        lua_insert( openbus::Openbus::LuaVM, -2 ) ;
        lua_pcall( openbus::Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( openbus::Openbus::LuaVM, -1 ) ;
        lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( openbus::Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( openbus::Openbus::LuaVM, this ) ;
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
      lua_settable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IComponent Lua:%p C:%p]\n", ptr, this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "[IComponent::IComponent() FIM]\n\n" ) ;
    #endif
    }

    IComponent::~IComponent ( void )
    {
    #if VERBOSE
      printf( "[Destruindo objeto IComponent (%p)...]\n", this ) ;
      lua_pushlightuserdata( openbus::Openbus::LuaVM, this ) ;
      lua_gettable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( openbus::Openbus::LuaVM, -1 ) ) ;
      lua_pop( openbus::Openbus::LuaVM, 1 ) ;
    #endif
    lua_pushlightuserdata( openbus::Openbus::LuaVM, this ) ;
    lua_pushnil( openbus::Openbus::LuaVM ) ;
    lua_settable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Objeto IComponent(%p) destruido!]\n\n", this ) ;
    #endif
    }

    void  IComponent::addFacet ( openbus::String name, openbus::String interface_name, void * facet_servant)
    {
    #if VERBOSE
      printf( "[IComponent::addFacet() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "  [Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_pushlightuserdata( openbus::Openbus::LuaVM, this ) ;
      lua_gettable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IComponent Lua:%p C:%p]\n", lua_topointer( openbus::Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( openbus::Openbus::LuaVM, -1, "addFacet" ) ;
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo addFacet empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( openbus::Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "  [name=%s empilhado]\n", name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( openbus::Openbus::LuaVM, interface_name ) ;
    #if VERBOSE
      printf( "  [interface_name=%s empilhado]\n", interface_name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( openbus::Openbus::LuaVM, facet_servant ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [facet_servant(%p) empilhado]\n", lua_topointer( openbus::Openbus::LuaVM, -1 ) ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( openbus::Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( openbus::Openbus::LuaVM, "tostring" ) ;
        lua_insert( openbus::Openbus::LuaVM, -2 ) ;
        lua_pcall( openbus::Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( openbus::Openbus::LuaVM, -1 ) ;
        lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao %s]\nname", returnValue ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
    }

    void IComponent::addFacet ( openbus::String name, openbus::String interface_name, \
            char* constructor_name, void* facet_servant )
    {
    #if VERBOSE
      printf( "[IComponent::addFacet() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "  [Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_pushlightuserdata( openbus::Openbus::LuaVM, this ) ;
      lua_gettable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IComponent Lua:%p C:%p]\n", lua_topointer( openbus::Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( openbus::Openbus::LuaVM, -1, "addFacet" ) ;
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo addFacet empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( openbus::Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "  [name=%s empilhado]\n", name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( openbus::Openbus::LuaVM, interface_name ) ;
    #if VERBOSE
      printf( "  [interface_name=%s empilhado]\n", interface_name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      tolua_pushusertype( openbus::Openbus::LuaVM, facet_servant, constructor_name ) ;
    #if VERBOSE
      printf( "  [facet_servant(%p) empilhado]\n", lua_topointer( openbus::Openbus::LuaVM, -1 ) ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( openbus::Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( openbus::Openbus::LuaVM, "tostring" ) ;
        lua_insert( openbus::Openbus::LuaVM, -2 ) ;
        lua_pcall( openbus::Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( openbus::Openbus::LuaVM, -1 ) ;
        lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao %s]\nname", returnValue ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
    }

    void IComponent::_getFacet ( void* ptr, openbus::String facet_interface )
    {
    #if VERBOSE
      printf( "[IComponent::getFacet() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "  [Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_getglobal( openbus::Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( openbus::Openbus::LuaVM, this ) ;
      lua_gettable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IComponent Lua:%p C:%p]\n", \
        lua_topointer( openbus::Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( openbus::Openbus::LuaVM, -1, "getFacet" ) ;
    #if VERBOSE
      printf( "  [metodo getFacet empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
    #endif
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
      lua_pushstring( openbus::Openbus::LuaVM, facet_interface ) ;
    #if VERBOSE
      printf( "  [facet_interface=%s empilhado]\n", facet_interface ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
    #endif
      if ( lua_pcall( openbus::Openbus::LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( openbus::Openbus::LuaVM, "tostring" ) ;
        lua_insert( openbus::Openbus::LuaVM, -2 ) ;
        lua_pcall( openbus::Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( openbus::Openbus::LuaVM, -1 ) ;
        lua_pop( openbus::Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao %s]\n", returnValue ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
        printf( "[IComponent::getFacet() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      lua_getglobal( openbus::Openbus::LuaVM, "oil" ) ;
      lua_getfield( openbus::Openbus::LuaVM, -1, "narrow" ) ;
      lua_pushvalue( openbus::Openbus::LuaVM, -3 ) ;
      lua_pushstring( openbus::Openbus::LuaVM, facet_interface ) ;
      lua_pcall( openbus::Openbus::LuaVM, 2, 1, 0 ) ;
    #if VERBOSE
      const void* luaRef = lua_topointer( openbus::Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( openbus::Openbus::LuaVM, ptr ) ;
      lua_insert( openbus::Openbus::LuaVM, -2 ) ;
      lua_settable( openbus::Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [OBJ Lua:%p C:%p]\n", luaRef, ptr ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( openbus::Openbus::LuaVM, lua_type( openbus::Openbus::LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( openbus::Openbus::LuaVM, 2 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( openbus::Openbus::LuaVM ) ) ;
      printf( "[IComponent::getFacet() FIM]\n\n" ) ;
    #endif
    }
  }
}

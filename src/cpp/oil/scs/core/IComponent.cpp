/*
* oil/scs/core/IComponent.cpp
*/

#include <openbus/oil/scs/core/IComponent.h>
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
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "\t[Construindo objeto IComponent]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "IComponent" ) ;
      lua_pushstring( Openbus::LuaVM, "IDL:scs/core/IComponent:1.0" ) ;
    #if VERBOSE
      printf( "\t[parametro name=%s empilhado]\n", "IDL:scs/core/IComponent:1.0" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushnumber( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[parametro 1 empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      printf( "\t[Chamando oil.newobject]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_pushstring( Openbus::LuaVM, "newobject" ) ;
      lua_gettable( Openbus::LuaVM, -2 ) ;
      lua_remove( Openbus::LuaVM, -2 ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[parametro IComponent empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, "IDL:scs/core/IComponent:1.0") ;
    #if VERBOSE
      printf( "\t[parametro IDL:scs/core/IComponent:1.0 empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IComponent Lua:%p C:%p]\n", ptr, this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IComponent::IComponent() FIM]\n\n" ) ;
    #endif
    }

    IComponent::IComponent ( openbus::String name )
    {
    #if VERBOSE
      printf( "[IComponent::IComponent() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "\t[Construindo objeto IComponent]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "IComponent" ) ;
      lua_pushstring( Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "\t[parametro name=%s empilhado]\n", name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushnumber( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[parametro 1 empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      printf( "\t[Chamando oil.newobject]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_pushstring( Openbus::LuaVM, "newobject" ) ;
      lua_gettable( Openbus::LuaVM, -2 ) ;
      lua_remove( Openbus::LuaVM, -2 ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[parametro IComponent empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, "IDL:scs/core/IComponent:1.0") ;
    #if VERBOSE
      printf( "\t[parametro IDL:scs/core/IComponent:1.0 empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::IComponent() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IComponent Lua:%p C:%p]\n", ptr, this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IComponent::IComponent() FIM]\n\n" ) ;
    #endif
    }

    IComponent::~IComponent ()
    {
    #if VERBOSE
      printf( "[Destruindo objeto IComponent (%p)...]\n", this ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #endif
    lua_pushlightuserdata( Openbus::LuaVM, this ) ;
    lua_pushnil( Openbus::LuaVM ) ;
    lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Objeto IComponent(%p) destruido!]\n\n", this ) ;
    #endif
    }

    void  IComponent::addFacet ( openbus::String name, openbus::String interface_name, void * facet_servant)
    {
    #if VERBOSE
      printf( "[IComponent::addFacet() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IComponent Lua:%p C:%p]\n", lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "addFacet" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo addFacet empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "\t[name=%s empilhado]\n", name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, interface_name ) ;
    #if VERBOSE
      printf( "\t[interface_name=%s empilhado]\n", interface_name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, facet_servant ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[facet_servant(%p) empilhado]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\nname", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
    }

    void IComponent::addFacet ( openbus::String name, openbus::String interface_name, \
            char* constructor_name, void* facet_servant )
    {
    #if VERBOSE
      printf( "[IComponent::addFacet() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IComponent Lua:%p C:%p]\n", lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "addFacet" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo addFacet empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "\t[name=%s empilhado]\n", name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, interface_name ) ;
    #if VERBOSE
      printf( "\t[interface_name=%s empilhado]\n", interface_name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      tolua_pushusertype( Openbus::LuaVM, facet_servant, constructor_name ) ;
    #if VERBOSE
      printf( "\t[facet_servant(%p) empilhado]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\nname", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::addFacet() FIM]\n\n" ) ;
      #endif
    }

    void IComponent::loadidl( openbus::String idl )
    {
    #if VERBOSE
      printf( "[IComponent::loadidl() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_getfield( Openbus::LuaVM, -1, "loadidl" ) ;
      lua_remove( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[metodo loadidl empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, idl ) ;
    #if VERBOSE
      printf( "\t[idl=%s empilhado]\n", idl ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 1, 0, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\nname", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::loadidl() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::loadidl() FIM]\n\n" ) ;
      #endif
    }

    void IComponent::loadidlfile( openbus::String idlfilename )
    {
    #if VERBOSE
      printf( "[IComponent::loadidlfile() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_getfield( Openbus::LuaVM, -1, "loadidlfile" ) ;
      lua_remove( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[metodo loadidlfile empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, idlfilename ) ;
    #if VERBOSE
      printf( "\t[idlfilename=%s empilhado]\n", idlfilename ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 1, 0, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\nname", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::loadidlfile() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::loadidlfile() FIM]\n\n" ) ;
      #endif
    }

    void IComponent::_getFacet ( void* ptr, openbus::String facet_interface )
    {
    #if VERBOSE
      printf( "[IComponent::getFacet() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Carregando proxy para IComponent]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IComponent Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "getFacet" ) ;
    #if VERBOSE
      printf( "\t[metodo getFacet empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_pushstring( Openbus::LuaVM, facet_interface ) ;
    #if VERBOSE
      printf( "\t[facet_interface=%s empilhado]\n", facet_interface ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\n", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IComponent::getFacet() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_getfield( Openbus::LuaVM, -1, "narrow" ) ;
      lua_pushvalue( Openbus::LuaVM, -3 ) ;
      lua_pushstring( Openbus::LuaVM, facet_interface ) ;
      lua_pcall( Openbus::LuaVM, 2, 1, 0 ) ;
    #if VERBOSE
      const void* luaRef = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, ptr ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[OBJ Lua:%p C:%p]\n", luaRef, ptr ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 2 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IComponent::getFacet() FIM]\n\n" ) ;
    #endif
    }
  }
}

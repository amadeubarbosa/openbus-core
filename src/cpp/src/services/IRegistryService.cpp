/*
* services/IRegistryService.cpp
*/

#include "IRegistryService.h"
#include <lua.hpp>
#include <string.h>

namespace openbus {
  namespace services {
    IRegistryService::IRegistryService( String reference, String interface )
    {
    #if VERBOSE
      printf( "[IRegistryService::IRegistryService() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_getfield( Openbus::LuaVM, -1, "newproxy" ) ;
      lua_pushstring( Openbus::LuaVM, reference ) ;
      lua_pushstring( Openbus::LuaVM, interface ) ;
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
        throw returnValue ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, (void *) this ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IRegistryService Lua:%p C:%p]\n", \
        ptr, (void *) this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IRegistryService::IRegistryService() FIM]\n\n" ) ;
    #endif
    }

    IRegistryService::IRegistryService ( void )
    {
    }

    IRegistryService::~IRegistryService ( void )
    {
    #if VERBOSE
      printf( "[Destruindo objeto IRegistryService (%p)...]\n", (void*) this ) ;
      lua_pushlightuserdata( Openbus::LuaVM, (void *) this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #endif
    lua_pushlightuserdata( Openbus::LuaVM, (void *) this ) ;
    lua_pushnil( Openbus::LuaVM ) ;
    lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Objeto IRegistryService(%p) destruido!]\n\n", (void*) this ) ;
    #endif
    }

    bool IRegistryService::Register ( services::ServiceOffer* aServiceOffer, \
      char*& outIdentifier )
    {
      bool returnValue ;
      size_t size ;
      Property* property ;
      int len, x ;
    #if VERBOSE
      printf( "[IRegistryService::Register(ServiceOffer,RegistryIdentifier) COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, (void*) this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), (void *) this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "register" ) ;
    #if VERBOSE
      printf( "  [metodo register empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [Criando objeto ServiceOffer]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      lua_pushstring( Openbus::LuaVM, "type" ) ;
      lua_pushstring( Openbus::LuaVM, aServiceOffer->type ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
    #if VERBOSE
      printf( "  [ServiceOffer.type empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, "description" ) ;
      lua_pushstring( Openbus::LuaVM, aServiceOffer->description ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
    #if VERBOSE
      printf( "  [ServiceOffer.description empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, "properties" ) ;
      lua_newtable( Openbus::LuaVM ) ;
    #if VERBOSE
      printf( "  [Criando objeto ServiceOffer.properties]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( aServiceOffer->properties != NULL )
      {
        len = aServiceOffer->properties->length() ;
        for ( x = 0; x < len; x++ )
        {
          property = aServiceOffer->properties->getmember( x ) ;
          lua_pushnumber( Openbus::LuaVM, x + 1 ) ;
          lua_newtable( Openbus::LuaVM ) ;
        #if VERBOSE
          printf( "  [Criando objeto ServiceOffer.properties[%d] length=%d]\n", x, len ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "name" ) ;
          lua_pushstring( Openbus::LuaVM, property->name ) ;
          lua_settable( Openbus::LuaVM, -3 ) ;
        #if VERBOSE
          printf( "  [Criando objeto ServiceOffer.properties[%d].name = %s]\n", x, property->name ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "value" ) ;
          lua_newtable( Openbus::LuaVM ) ;
          if ( property->value != NULL )
          {
            luaidl::cpp::types::String str ;
          #if VERBOSE
            printf( "  [Criando objeto ServiceOffer.properties[%d].value length=%d]\n", \
                x, property->value->length() ) ;
            printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
          #endif
            for ( int y = 0; y < property->value->length(); y++ )
            {
              str = property->value->getmember( y ) ;
              lua_pushnumber( Openbus::LuaVM, y + 1 ) ;
              lua_pushstring( Openbus::LuaVM, str ) ;
              lua_settable( Openbus::LuaVM, -3 ) ;
            #if VERBOSE
              printf( "  [Criando objeto ServiceOffer.properties[%d].value[%d] = %s]\n", \
                  x, y, str ) ;
              printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
            #endif
            }
          } /* if */
          lua_settable( Openbus::LuaVM, -3 ) ;
          lua_settable( Openbus::LuaVM, -3 ) ;
        } /* for */
      } /* if */
      lua_settable( Openbus::LuaVM, -3 ) ;
    #if VERBOSE
      printf( "  [ServiceOffer.properties empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, "member" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, (void*) aServiceOffer->member ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IComponent Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), (void *) aServiceOffer->member ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_settable( Openbus::LuaVM, -3 ) ;
    #if VERBOSE
      printf( "  [ServiceOffer.IComponent empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 2, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IRegistryService::Register(ServiceOffer,RegistryIdentifier) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      char* luastring = (char*) lua_tolstring( Openbus::LuaVM, -1, &size ) ;
      outIdentifier = new char[ size + 1 ] ;
      outIdentifier[size] = '\0' ;
      memcpy( outIdentifier, luastring, size ) ;
    #if VERBOSE
      printf( "  [outIdentifier=%s]\n", outIdentifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
      returnValue = lua_toboolean( Openbus::LuaVM, -1 ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando %d]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IRegistryService::Register(ServiceOffer,RegistryIdentifier) FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IRegistryService::unregister( RegistryIdentifier identifier )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[IRegistryService::unregister(RegistryIdentifier) COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, (void*) this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), (void *) this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "unregister" ) ;
    #if VERBOSE
      printf( "  [metodo unregister empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_pushstring( Openbus::LuaVM, identifier ) ;
    #if VERBOSE
      printf( "  [RegistryIndentifier=%s empilhado]\n", identifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao %s]\n", returnValue ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IRegistryService::unregister(RegistryIdentifier) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, -1 ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando %d]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IRegistryService::unregister(RegistryIdentifier) FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IRegistryService::update( RegistryIdentifier identifier, PropertyList* newProperties )
    {
      bool returnValue ;
      Property* property ;
      int len ;
    #if VERBOSE
      printf( "[IRegistryService::update( RegistryIdentifier, PropertyList ) COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, (void*) this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), (void *) this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "update" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo update empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, identifier ) ;
    #if VERBOSE
      printf( "  [RegistryIdentifier=%s empilhado]\n", identifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      if ( newProperties != NULL )
      {
        len = newProperties->length() ;
        for ( int x = 0; x < len; x++ )
        {
          property = newProperties->getmember( x ) ;
          lua_pushnumber( Openbus::LuaVM, x + 1 ) ;
          lua_newtable( Openbus::LuaVM ) ;
        #if VERBOSE
          printf( "  [Criando objeto newProperties[%d] length=%d]\n", x, len ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "name" ) ;
          lua_pushstring( Openbus::LuaVM, property->name ) ;
          lua_settable( Openbus::LuaVM, -3 ) ;
        #if VERBOSE
          printf( "  [Criando objeto newProperties[%d].name = %s]\n", x, property->name ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "value" ) ;
          lua_newtable( Openbus::LuaVM ) ;
          if ( property->value != NULL )
          {
            luaidl::cpp::types::String str ;
          #if VERBOSE
            printf( "  [Criando objeto newProperties.properties[%d].value length=%d]\n", \
                x, property->value->length() ) ;
            printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
          #endif
            for ( int y = 0; y < property->value->length(); y++ )
            {
              str = property->value->getmember( y ) ;
              lua_pushnumber( Openbus::LuaVM, x + 1 ) ;
              lua_pushstring( Openbus::LuaVM, str ) ;
              lua_settable( Openbus::LuaVM, -3 ) ;
            #if VERBOSE
              printf( "  [Criando objeto ServiceOffer.properties[%d].value[%d] = %s]\n", \
                  x, y, str ) ;
              printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
            #endif
            }
          } /* if */
          lua_settable( Openbus::LuaVM, -3 ) ;
          lua_settable( Openbus::LuaVM, -3 ) ;
        } /* for */
      } /* if */
      if ( lua_pcall( Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao %s]\n", returnValue ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IRegistryService::update( RegistryIdentifier, PropertyList ) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, -1 ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando %d]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IRegistryService::update(RegistryIdentifier, PropertyList) FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    ServiceOfferList* IRegistryService::find( String type, PropertyList* criteria )
    {
      ServiceOfferList* returnValue = NULL ;
      Property* property ;
      int len ;
    #if VERBOSE
      printf( "[IRegistryService::find( String type, PropertyList criteria ) COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, (void*) this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), (void *) this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "find" ) ;
    #if VERBOSE
      printf( "  [metodo find empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_pushstring( Openbus::LuaVM, type ) ;
    #if VERBOSE
      printf( "  [type=%s empilhado]\n", type ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      if ( criteria != NULL )
      {
        len = criteria->length() ;
        for ( int x = 0; x < len; x++ )
        {
          property = criteria->getmember( x ) ;
          lua_pushnumber( Openbus::LuaVM, x + 1 ) ;
          lua_newtable( Openbus::LuaVM ) ;
        #if VERBOSE
          printf( "  [Criando objeto criteria[%d] length=%d]\n", x, len ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "name" ) ;
          lua_pushstring( Openbus::LuaVM, property->name ) ;
          lua_settable( Openbus::LuaVM, -3 ) ;
        #if VERBOSE
          printf( "  [Criando objeto criteria[%d].name = %s]\n", x, property->name ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "value" ) ;
          lua_newtable( Openbus::LuaVM ) ;
          if ( property->value != NULL )
          {
            luaidl::cpp::types::String str ;
          #if VERBOSE
            printf( "  [Criando objeto ServiceOffer.properties[%d].value length=%d]\n", \
                x, property->value->length() ) ;
            printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
          #endif
            for ( int y = 0; y < property->value->length(); y++ )
            {
              str = property->value->getmember( y ) ;
              lua_pushnumber( Openbus::LuaVM, x + 1 ) ;
              lua_pushstring( Openbus::LuaVM, str ) ;
              lua_settable( Openbus::LuaVM, -3 ) ;
            #if VERBOSE
              printf( "  [Criando objeto ServiceOffer.properties[%d].value[%d] = %s]\n", \
                  x, y, str ) ;
              printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
            #endif
            }
          } /* if */
          lua_settable( Openbus::LuaVM, -3 ) ;
          lua_settable( Openbus::LuaVM, -3 ) ;
        } /* for */
      } /* if */
      if ( lua_pcall( Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao %s]\n", returnValue ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IRegistryService::find( String type, PropertyList criteria ) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      returnValue = NULL ;
      for ( int x = 1; ; x++ )
      {
        lua_pushnumber( Openbus::LuaVM, x ) ;
        lua_gettable( Openbus::LuaVM, -2 ) ;
        if ( !lua_istable( Openbus::LuaVM, -1 ) )
        {
          break ;
        } else {
          if ( x == 1 )
          {
        #if VERBOSE
          printf( "  [gerando valor de retorno do tipo ServiceOfferList]\n" ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
            returnValue = new ServiceOfferList( 256 ) ;
          } /* if */
        #if VERBOSE
          printf( "  [serviceOfferList[%d]]\n", x ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          ServiceOffer* serviceOffer = new ServiceOffer ;
          lua_pushstring( Openbus::LuaVM, "type" ) ;
          lua_gettable( Openbus::LuaVM, -2 ) ;
          serviceOffer->type = lua_tostring( Openbus::LuaVM, -1 ) ;
          lua_pop( Openbus::LuaVM, 1 ) ;
        #if VERBOSE
          printf( "  [serviceOfferList[%d]->type=%s]\n", x, serviceOffer->type ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "description" ) ;
          lua_gettable( Openbus::LuaVM, -2 ) ;
          serviceOffer->description = lua_tostring( Openbus::LuaVM, -1 ) ;
          lua_pop( Openbus::LuaVM, 1 ) ;
        #if VERBOSE
          printf( "  [serviceOfferList[%d]->description=%s]\n", x, serviceOffer->description ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pushstring( Openbus::LuaVM, "member" ) ;
          lua_gettable( Openbus::LuaVM, -2 ) ;
        #if VERBOSE
          const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
        #endif
/*          lua_getfield( Openbus::LuaVM, -1, "getClassId" ) ;
          lua_pushvalue( Openbus::LuaVM, -2 ) ;
          lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
          lua_getfield( Openbus::LuaVM, -1, "name" ) ;*/
          serviceOffer->member = new scs::core::IComponent( "substituir depois..." ) ;
/*          lua_pop( Openbus::LuaVM, 2 ) ;*/
          lua_pushlightuserdata( Openbus::LuaVM, (void *) serviceOffer->member ) ;
          lua_insert( Openbus::LuaVM, -2 ) ;
          lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
        #if VERBOSE
          printf( "  [IComponent Lua:%p C:%p]\n", \
            ptr, (void *) serviceOffer->member ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          lua_pop( Openbus::LuaVM, 1 ) ;
        #if VERBOSE
          printf( "  [serviceOfferList[%d] desempilhada]\n", x ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
          returnValue->newmember( serviceOffer ) ;
        #if VERBOSE
          printf( "  [serviceOfferList[%d] criado...]\n", x ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
        } /* if */
      } /* for */
    /* retira indice da pilha e valor de retorno*/
      lua_pop( Openbus::LuaVM, 2 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IRegistryService::find( String type, PropertyList criteria ) FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

  }
}

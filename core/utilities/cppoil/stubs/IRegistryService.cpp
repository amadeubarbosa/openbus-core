/*
** stubs/IRegistryService.cpp
*/

#include "IRegistryService.h"
#include <lua.hpp>
#include <string.h>

namespace openbus {
  namespace services {

    Lua_State* IRegistryService::LuaVM = 0;

    IRegistryService::IRegistryService( String reference, String interface )
    {
      openbus = Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
    #if VERBOSE
      printf( "[IRegistryService::IRegistryService() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( LuaVM, "oil" ) ;
      lua_getfield( LuaVM, -1, "newproxy" ) ;
      lua_pushstring( LuaVM, reference ) ;
      lua_pushstring( LuaVM, interface ) ;
      if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
        const char * returnValue ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
        throw returnValue ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( LuaVM, (void *) this ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IRegistryService Lua:%p C:%p]\n", \
        ptr, (void *) this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IRegistryService::IRegistryService() FIM]\n\n" ) ;
    #endif
    }

    IRegistryService::IRegistryService ( void )
    {
      openbus = Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
    }

    IRegistryService::~IRegistryService ( void )
    {
    #if VERBOSE
      printf( "[Destruindo objeto IRegistryService (%p)...]\n", (void*) this ) ;
    #endif
      lua_pushlightuserdata( LuaVM, (void *) this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( LuaVM, -1 ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
      lua_pushlightuserdata( LuaVM, (void *) this ) ;
      lua_pushnil( LuaVM ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
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
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, (void*) this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), (void *) this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "register" ) ;
    #if VERBOSE
      printf( "\t[metodo register empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[Criando objeto ServiceOffer]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_newtable( LuaVM ) ;
      lua_pushstring( LuaVM, "properties" ) ;
      lua_newtable( LuaVM ) ;
    #if VERBOSE
      printf( "\t[Criando objeto ServiceOffer.properties]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( aServiceOffer->properties != NULL )
      {
        len = aServiceOffer->properties->length() ;
        for ( x = 0; x < len; x++ )
        {
          property = aServiceOffer->properties->getmember( x ) ;
          lua_pushnumber( LuaVM, x + 1 ) ;
          lua_newtable( LuaVM ) ;
        #if VERBOSE
          printf( "\t[Criando objeto ServiceOffer.properties[%d] length=%d]\n", x, len ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          lua_pushstring( LuaVM, "name" ) ;
          lua_pushstring( LuaVM, property->name ) ;
          lua_settable( LuaVM, -3 ) ;
        #if VERBOSE
          printf( "\t[Criando objeto ServiceOffer.properties[%d].name = %s]\n", x, property->name ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          lua_pushstring( LuaVM, "value" ) ;
          lua_newtable( LuaVM ) ;
          if ( property->value != NULL )
          {
            luaidl::cpp::types::String str ;
          #if VERBOSE
            printf( "\t[Criando objeto ServiceOffer.properties[%d].value length=%d]\n", \
                x, property->value->length() ) ;
            printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
          #endif
            for ( int y = 0; y < property->value->length(); y++ )
            {
              str = property->value->getmember( y ) ;
              lua_pushnumber( LuaVM, y + 1 ) ;
              lua_pushstring( LuaVM, str ) ;
              lua_settable( LuaVM, -3 ) ;
            #if VERBOSE
              printf( "\t[Criando objeto ServiceOffer.properties[%d].value[%d] = %s]\n", \
                  x, y, str ) ;
              printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
            #endif
            }
          } /* if */
          lua_settable( LuaVM, -3 ) ;
          lua_settable( LuaVM, -3 ) ;
        } /* for */
      } /* if */
      lua_settable( LuaVM, -3 ) ;
    #if VERBOSE
      printf( "\t[ServiceOffer.properties empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, "member" ) ;
      lua_pushlightuserdata( LuaVM, (void*) aServiceOffer->member ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IComponent Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), (void *) aServiceOffer->member ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_settable( LuaVM, -3 ) ;
    #if VERBOSE
      printf( "\t[ServiceOffer.IComponent empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 2, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IRegistryService::Register(ServiceOffer,RegistryIdentifier) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      char* luastring = (char*) lua_tolstring( LuaVM, -1, &size ) ;
      outIdentifier = new char[ size + 1 ] ;
      outIdentifier[size] = '\0' ;
      memcpy( outIdentifier, luastring, size ) ;
    #if VERBOSE
      printf( "\t[outIdentifier=%s]\n", outIdentifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
      returnValue = lua_toboolean( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[retornando %d]\n", returnValue ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IRegistryService::Register(ServiceOffer,RegistryIdentifier) FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IRegistryService::unregister( RegistryIdentifier identifier )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[IRegistryService::unregister(RegistryIdentifier) COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, (void*) this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), (void *) this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "unregister" ) ;
    #if VERBOSE
      printf( "\t[metodo unregister empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_insert( LuaVM, -2 ) ;
      lua_pushstring( LuaVM, identifier ) ;
    #if VERBOSE
      printf( "\t[RegistryIndentifier=%s empilhado]\n", identifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\n", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IRegistryService::unregister(RegistryIdentifier) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      returnValue = lua_toboolean( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[retornando %d]\n", returnValue ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
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
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, (void*) this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), (void *) this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "update" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo update empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, identifier ) ;
    #if VERBOSE
      printf( "\t[RegistryIdentifier=%s empilhado]\n", identifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_newtable( LuaVM ) ;
      if ( newProperties != NULL )
      {
        len = newProperties->length() ;
        for ( int x = 0; x < len; x++ )
        {
          property = newProperties->getmember( x ) ;
          lua_pushnumber( LuaVM, x + 1 ) ;
          lua_newtable( LuaVM ) ;
        #if VERBOSE
          printf( "\t[Criando objeto newProperties[%d] length=%d]\n", x, len ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          lua_pushstring( LuaVM, "name" ) ;
          lua_pushstring( LuaVM, property->name ) ;
          lua_settable( LuaVM, -3 ) ;
        #if VERBOSE
          printf( "\t[Criando objeto newProperties[%d].name = %s]\n", x, property->name ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          lua_pushstring( LuaVM, "value" ) ;
          lua_newtable( LuaVM ) ;
          if ( property->value != NULL )
          {
            luaidl::cpp::types::String str ;
          #if VERBOSE
            printf( "\t[Criando objeto newProperties.properties[%d].value length=%d]\n", \
                x, property->value->length() ) ;
            printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
          #endif
            for ( int y = 0; y < property->value->length(); y++ )
            {
              str = property->value->getmember( y ) ;
              lua_pushnumber( LuaVM, x + 1 ) ;
              lua_pushstring( LuaVM, str ) ;
              lua_settable( LuaVM, -3 ) ;
            #if VERBOSE
              printf( "\t[Criando objeto ServiceOffer.properties[%d].value[%d] = %s]\n", \
                  x, y, str ) ;
              printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
            #endif
            }
          } /* if */
          lua_settable( LuaVM, -3 ) ;
          lua_settable( LuaVM, -3 ) ;
        } /* for */
      } /* if */
      if ( lua_pcall( LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\n", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IRegistryService::update( RegistryIdentifier, PropertyList ) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      returnValue = lua_toboolean( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[retornando %d]\n", returnValue ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IRegistryService::update(RegistryIdentifier, PropertyList) FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    ServiceOfferList* IRegistryService::find( PropertyList* criteria )
    {
      ServiceOfferList* returnValue = NULL ;
      Property* property ;
      int len ;
    #if VERBOSE
      printf( "[IRegistryService::find( PropertyList criteria ) COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Criando proxy para IRegistryService]\n" ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, (void*) this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IRegistryService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), (void *) this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "find" ) ;
    #if VERBOSE
      printf( "\t[metodo find empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_insert( LuaVM, -2 ) ;
      lua_newtable( LuaVM ) ;
      if ( criteria != NULL )
      {
        len = criteria->length() ;
        for ( int x = 0; x < len; x++ )
        {
          property = criteria->getmember( x ) ;
          lua_pushnumber( LuaVM, x + 1 ) ;
          lua_newtable( LuaVM ) ;
        #if VERBOSE
          printf( "\t[Criando objeto criteria[%d] length=%d]\n", x, len ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          lua_pushstring( LuaVM, "name" ) ;
          lua_pushstring( LuaVM, property->name ) ;
          lua_settable( LuaVM, -3 ) ;
        #if VERBOSE
          printf( "\t[Criando objeto criteria[%d].name = %s]\n", x, property->name ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          lua_pushstring( LuaVM, "value" ) ;
          lua_newtable( LuaVM ) ;
          if ( property->value != NULL )
          {
            luaidl::cpp::types::String str ;
          #if VERBOSE
            printf( "\t[Criando objeto ServiceOffer.properties[%d].value length=%d]\n", \
                x, property->value->length() ) ;
            printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
          #endif
            for ( int y = 0; y < property->value->length(); y++ )
            {
              str = property->value->getmember( y ) ;
              lua_pushnumber( LuaVM, x + 1 ) ;
              lua_pushstring( LuaVM, str ) ;
              lua_settable( LuaVM, -3 ) ;
            #if VERBOSE
              printf( "\t[Criando objeto ServiceOffer.properties[%d].value[%d] = %s]\n", \
                  x, y, str ) ;
              printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
            #endif
            }
          } /* if */
          lua_settable( LuaVM, -3 ) ;
          lua_settable( LuaVM, -3 ) ;
        } /* for */
      } /* if */
      if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
              lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * returnValue ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        returnValue = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao %s]\n", returnValue ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IRegistryService::find( PropertyList criteria ) FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      returnValue = NULL ;
      for ( int x = 1; ; x++ )
      {
        lua_pushnumber( LuaVM, x ) ;
        lua_gettable( LuaVM, -2 ) ;
        if ( !lua_istable( LuaVM, -1 ) )
        {
          break ;
        } else {
          if ( x == 1 )
          {
        #if VERBOSE
          printf( "\t[gerando valor de retorno do tipo ServiceOfferList]\n" ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
            returnValue = new ServiceOfferList( 256 ) ;
          } /* if */
        #if VERBOSE
          printf( "\t[serviceOfferList[%d]]\n", x ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          ServiceOffer* serviceOffer = new ServiceOffer ;
          lua_pushstring( LuaVM, "member" ) ;
          lua_gettable( LuaVM, -2 ) ;
        #if VERBOSE
          const void* ptr = lua_topointer( LuaVM, -1 ) ;
        #endif
/*          lua_getfield( LuaVM, -1, "getComponentId" ) ;
          lua_pushvalue( LuaVM, -2 ) ;
          lua_pcall( LuaVM, 1, 1, 0 ) ;
          lua_getfield( LuaVM, -1, "name" ) ;*/
          serviceOffer->member = new scs::core::IComponent( "substituir depois..." ) ;
/*          lua_pop( LuaVM, 2 ) ;*/
          lua_pushlightuserdata( LuaVM, (void *) serviceOffer->member ) ;
          lua_insert( LuaVM, -2 ) ;
          lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
        #if VERBOSE
          printf( "\t[IComponent Lua:%p C:%p]\n", \
            ptr, (void *) serviceOffer->member ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          lua_pop( LuaVM, 1 ) ;
        #if VERBOSE
          printf( "\t[serviceOfferList[%d] desempilhada]\n", x ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
          returnValue->newmember( serviceOffer ) ;
        #if VERBOSE
          printf( "\t[serviceOfferList[%d] criado...]\n", x ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
        } /* if */
      } /* for */
    /* retira indice da pilha e valor de retorno*/
      lua_pop( LuaVM, 2 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IRegistryService::find( PropertyList criteria ) FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

  }
}

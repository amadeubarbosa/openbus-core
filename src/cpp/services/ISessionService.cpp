/*
* services/ISessionService.cpp
*/

#include <services/ISessionService.h>
#include <lua.hpp>
#include <string.h>

namespace openbus {
  namespace services {

    SessionEventSink::SessionEventSink() {}
    SessionEventSink::~SessionEventSink() {}

    int SessionEventSink::_push_bind( Lua_State* L )
    {
      return 0 ;
    }

    int SessionEventSink::_disconnect_bind( Lua_State* L )
    {
      return 0 ;
    }

    ISessionService::ISessionService( void ) {}
    ISessionService::~ISessionService( void ) {}

    ISession::ISession() {}
    ISession::~ISession()
    {
    #if VERBOSE
      printf( "[Destruindo objeto ISession (%p)...]\n", this ) ;
    #endif
    #if VERBOSE
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #endif
    lua_pushlightuserdata( Openbus::LuaVM, this ) ;
    lua_pushnil( Openbus::LuaVM ) ;
    lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Objeto ISession(%p) destruido!]\n\n", this ) ;
    #endif
    }

    SessionIdentifier ISession::getIdentifier( void )
    {
      char* returnValue ;
      size_t size ;
    #if VERBOSE
      printf( "[ISession::getIdentifier() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para ISession]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ISession Lua:%p C:%p]\n", lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "getIdentifier" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo getIdentifier empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
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
        printf( "[ISession::getIdentifier() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      const char* luastring = lua_tolstring( Openbus::LuaVM, -1, &size ) ;
      returnValue = new char[ size + 1 ] ;
      memcpy( returnValue, luastring, size ) ;
      returnValue[ size ] = '\0' ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando %s]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[ISession::getIdentifier() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    MemberIdentifier  ISession::addMember( scs::core::IComponent* member )
    {
      char* returnValue ;
      size_t size ;
    #if VERBOSE
      printf( "[ISession::addMember() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para ISession]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ISession Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "addMember" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo addMember empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, member ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [parametro IComponent empilhado]\n" ) ;
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
        printf( "[ISession::addMember() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      const char* luastring = lua_tolstring( Openbus::LuaVM, -1, &size ) ;
      returnValue = new char[ size + 1 ] ;
      memcpy( returnValue, luastring, size ) ;
      returnValue[ size ] = '\0' ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando %s]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[ISession::addMember() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool ISession::removeMember( MemberIdentifier memberIdentifier )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[ISession::removeMember() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para ISession]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ISession Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "removeMember" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo removeMember empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, memberIdentifier ) ;
    #if VERBOSE
      printf( "  [parametro MemberIdentifier=%s]\n", memberIdentifier ) ;
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
        printf( "[ISession::removeMember() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, -1 ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando %d]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[ISession::removeMember() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

  /* nao esta implementado em Lua */
    scs::core::IComponentSeq* ISession::getMembers( void )
    {
      return NULL ;
    }

    bool ISessionService::createSession \
      ( scs::core::IComponent* member, ISession*& session, char*& outMemberIdentifier )
    {
      bool returnValue ;
      size_t size ;
    #if VERBOSE
      printf( "[ISessionService::createSession() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para ISessionService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ISessionService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "createSession" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo createSession empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, member ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IComponent Lua:%p C:%p]\n", lua_topointer( Openbus::LuaVM, -1 ), member ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 3, 0 ) != 0 ) {
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
        printf( "[ISessionService::createSession() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
      const char* luastring = lua_tolstring( Openbus::LuaVM, -1, &size ) ;
      outMemberIdentifier = new char[ size + 1 ] ;
      memcpy( outMemberIdentifier, luastring, size ) ;
      outMemberIdentifier[ size ] = '\0' ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [outMemberIdentifier=%s]\n", outMemberIdentifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    /* faco delete desse cara?? */
      session = new ISession ;
    #if VERBOSE
      const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, session ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ISession Lua:%p C:%p]\n", ptr, session ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
      returnValue = lua_toboolean( Openbus::LuaVM, -1 ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando %d]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[ISessionService::createSession() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    ISession* ISessionService::getSession( void )
    {
      ISession* returnValue ;
    #if VERBOSE
      printf( "[ISessionService::getSession() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para ISessionService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ISessionService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "getSession" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo getSession empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
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
        printf( "[ISessionService::getSession() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    /* faco delete desse cara ?? */
      returnValue = new ISession ;
    #if VERBOSE
      const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, returnValue ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ISession Lua:%p C:%p]\n", \
        ptr, (void *) returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
    #if VERBOSE
      printf( "  [retornando ISession = %p]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[ISessionService::getSession() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

  }
}

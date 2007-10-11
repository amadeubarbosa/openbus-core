/*
* services/ISessionService.cpp
*/

#include <services/ISessionService.h>
#include <lua.hpp>
#include <string.h>

namespace openbus {
  namespace services {

    SessionEventSink::SessionEventSink()
    {
    #if VERBOSE
      printf( "[SessionEventSink::SessionEventSink() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando objeto SessionEventSink]\n" ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      ptr_luaimpl = (void*) lua_topointer( Openbus::LuaVM, -1 ) ;
      lua_pushvalue( Openbus::LuaVM, -1 ) ;
    #if VERBOSE
      printf( "  [Objeto Lua SessionEventSink criado (%p)]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      lua_pushstring( Openbus::LuaVM, "push" ) ;
      lua_pushcfunction( Openbus::LuaVM, SessionEventSink::_push_bind ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
      lua_pushstring( Openbus::LuaVM, "disconnect" ) ;
      lua_pushcfunction( Openbus::LuaVM, SessionEventSink::_disconnect_bind ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
    #if VERBOSE
      const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [SessionEventSink Lua:%p C:%p]\n", \
        ptr, this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[SessionEventSink::SessionEventSink() FIM]\n\n" ) ;
    #endif
    }
    SessionEventSink::~SessionEventSink() {}

    int SessionEventSink::_push_bind( Lua_State* L )
    {
      size_t size ;
      char* str ;
    #if VERBOSE
      printf( "  [SessionEventSink::_push_bind() COMECO]\n" ) ;
      printf( "    [Tamanho da pilha de Lua: %d]\n" , lua_gettop( L ) ) ;
    #endif
      lua_insert( L, 1 ) ;
      lua_gettable( L, LUA_REGISTRYINDEX ) ;
      SessionEventSink* sevsnk = (SessionEventSink*) lua_topointer( L, -1 ) ;
    #if VERBOSE
      printf( "    [SessionEventSink C++: %p]\n" , sevsnk ) ;
    #endif
      lua_pop( L, 1 ) ;
    #if VERBOSE
      printf( "    [Criando objeto SessionEvent...]\n" ) ;
    #endif
    /* quem faz delete desse cara?? */
      SessionEvent* sev = new SessionEvent ;
      lua_getfield( L, -1, "type" ) ;
      const char * luastring = lua_tolstring( L, -1, &size ) ;
      str = new char[ size + 1 ] ;
      memcpy( str, luastring, size ) ;
      str[ size ] = '\0' ;
      sev->type = str ;
    #if VERBOSE
      printf( "    [SessionEvent->type=%s]\n", sev->type ) ;
    #endif
      lua_pop( L, 1 ) ;
      lua_getfield( L, -1, "value" ) ;
      lua_getfield( L, -1, "_anyval" ) ;
      luastring = lua_tolstring( L, -1, &size ) ;
      str = new char[ size + 1 ] ;
      memcpy( str, luastring, size ) ;
      str[ size ] = '\0' ;
      sev->value = str ;
    #if VERBOSE
      printf( "    [SessionEvent->value=%s]\n",  sev->value ) ;
    #endif
      lua_pop( L, 3 ) ;
      sevsnk->push( sev ) ;
    #if VERBOSE
      printf( "    [Tamanho da pilha de Lua: %d]\n" , lua_gettop( L ) ) ;
      printf( "  [SessionEventSink::_push_bind() FIM]\n\n" ) ;
    #endif
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

    void ISession::push( SessionEvent* ev )
    {
    #if VERBOSE
      printf( "[ISession::push() COMECO]\n" ) ;
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
      lua_getfield( Openbus::LuaVM, -1, "push" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo push empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
    #if VERBOSE
      printf( "  [SessionEvent empilhado...]\n" ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, ev->type ) ;
      lua_setfield( Openbus::LuaVM, -2, "type" ) ;
    #if VERBOSE
      printf( "  [SessionEvent.type=%s empilhado...]\n", ev->type ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      lua_pushstring( Openbus::LuaVM, ev->value ) ;
      lua_setfield( Openbus::LuaVM, -2, "_anyval" ) ;
    #if VERBOSE
      printf( "  [SessionEvent.value._anyval=%s empilhado...]\n", ev->value ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oilcorbaidlstring" ) ;
      lua_setfield( Openbus::LuaVM, -2, "_anytype" ) ;
      lua_setfield( Openbus::LuaVM, -2, "value" ) ;
      if ( lua_pcall( Openbus::LuaVM, 3, 0, 0 ) != 0 ) {
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
        printf( "[ISession::push() FIM]\n\n" ) ;
      #endif
        throw returnValue ;
      } /* if */
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[ISession::push() FIM]\n\n" ) ;
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

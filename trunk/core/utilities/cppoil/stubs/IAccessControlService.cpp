/*
** stubs/IAccessControlService.cpp
*/

#include "IAccessControlService.h"
#include <string.h>
#include <lua.hpp>

namespace openbus {
  namespace services {

    Lua_State* ICredentialObserver::LuaVM = 0;
    Lua_State* IAccessControlService::LuaVM = 0;


    ICredentialObserver::ICredentialObserver()
    {
      openbus = Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
    #if VERBOSE
      printf( "[ICredentialObserver::ICredentialObserver() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Criando objeto ICredentialObserver]\n" ) ;
    #endif
      lua_getglobal( LuaVM, "orb" ) ;
      lua_getfield( LuaVM, -1, "newservant" ) ;
      lua_getglobal( LuaVM, "orb" ) ;
      lua_newtable( LuaVM ) ;
      ptr_luaimpl = (void*) lua_topointer( LuaVM, -1 ) ;
      lua_pushvalue( LuaVM, -1 ) ;
    #if VERBOSE
      printf( "\t[Objeto Lua ICredentialObserver criado (%p)]\n", lua_topointer( LuaVM, -1 ) ) ;
    #endif
    /* Cria uma referencia para o objeto C++ atraves do objeto em Lua.
    *  Esta referencia sera utilizada pelo metodo _credentialWasDeleted_bind com o intuito
    *  do mesmo saber a qual objeto ICredentialObserver a chamata ao metodo credentialWasDeleted
    *  deve ser passada.
    */
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
      lua_pushstring( LuaVM, "credentialWasDeleted" ) ;
      lua_pushcfunction( LuaVM, ICredentialObserver::_credentialWasDeleted_bind ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_pushnil(LuaVM);
      lua_pushstring( LuaVM, "IDL:openbusidl/acs/ICredentialObserver:1.0" ) ;
      if ( lua_pcall( LuaVM, 4, 1, 0 ) != 0 ) {
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
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[ICredentialObserver Lua:%p C:%p]\n", \
        ptr, this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[ICredentialObserver::ICredentialObserver() FIM]\n\n" ) ;
    #endif
    }

    ICredentialObserver::~ICredentialObserver()
    {
    #if VERBOSE
      printf( "[Destruindo objeto ICredentialObserver (%p)...]\n", this ) ;
    #endif
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( LuaVM, -1 ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_pushnil( LuaVM ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Liberando referencia Lua da implementacao:%p]\n", ptr_luaimpl ) ;
    #endif
      lua_pushlightuserdata( LuaVM, ptr_luaimpl ) ;
      lua_pushnil( LuaVM ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Objeto ICredentialObserver(%p) destruido!]\n\n", this ) ;
    #endif
    }

    int ICredentialObserver::_credentialWasDeleted_bind ( Lua_State* L )
    {
      size_t size ;
      char* str ;
    #if VERBOSE
      printf( "\t[ICredentialObserver::_credentialWasDeleted_bind() COMECO]\n" ) ;
      printf( "\t\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( L ) ) ;
    #endif
      lua_insert( L, 1 ) ;
      lua_gettable( L, LUA_REGISTRYINDEX ) ;
      ICredentialObserver* co = (ICredentialObserver*) lua_topointer( L, -1 ) ;
    #if VERBOSE
      printf( "\t\t[ICredentialObserver C++: %p]\n" , co ) ;
    #endif
      lua_pop( L, 1 ) ;
    #if VERBOSE
      printf( "\t\t[Criando objeto Credential...]\n" ) ;
    #endif
    /* quem faz delete desse cara?? */
      Credential* c = new Credential ;
      lua_getfield( L, -1, "owner" ) ;
      const char * luastring = lua_tolstring( L, -1, &size ) ;
      str = new char[ size + 1 ] ;
      memcpy( str, luastring, size ) ;
      str[ size ] = '\0' ;
      c->owner = str ;
    #if VERBOSE
      printf( "\t\t[credential->owner=%s]\n", c->owner ) ;
    #endif
      lua_pop( L, 1 ) ;
      lua_getfield( L, -1, "identifier" ) ;
      luastring = lua_tolstring( L, -1, &size ) ;
      str = new char[ size + 1 ] ;
      memcpy( str, luastring, size ) ;
      str[ size ] = '\0' ;
      c->identifier = str ;
    #if VERBOSE
      printf( "\t\t[credential->identifier=%s]\n",  c->identifier ) ;
    #endif
      lua_pop( L, 1 ) ;
      lua_getfield( L, -1, "delegate" ) ;
      luastring = lua_tolstring( L, -1, &size ) ;
      str = new char[ size + 1 ] ;
      memcpy( str, luastring, size ) ;
      str[ size ] = '\0' ;
      c->delegate = str ;
    #if VERBOSE
      printf( "\t\t[credential->delegate=%s]\n",  c->delegate ) ;
    #endif
      lua_pop( L, 2 ) ;
      co->credentialWasDeleted( c ) ;
    #if VERBOSE
      printf( "  \t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( L ) ) ;
      printf( "\t[ICredentialObserver::_credentialWasDeleted_bind() FIM]\n\n" ) ;
    #endif
      return 0 ;
    }

    IAccessControlService::IAccessControlService ( String reference, String interface )
    {
      registryService = NULL ;
      openbus = Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
    #if VERBOSE
      printf( "[IAccessControlService::IAccessControlService() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Criando proxy para IAccessControlService]\n" ) ;
    #endif
      lua_getglobal( LuaVM, "orb" ) ;
      lua_getfield( LuaVM, -1, "newproxy" ) ;
      lua_getglobal( LuaVM, "orb" ) ;
      lua_pushstring( LuaVM, reference ) ;
    #if VERBOSE
      printf( "\t[parametro reference=%s empilhado]\n", reference ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, interface ) ;
    #if VERBOSE
      printf( "\t[parametro interface=%s empilhado]\n", interface ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
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
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", ptr, this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::IAccessControlService() FIM]\n\n" ) ;
    #endif
    }

  /* Destrutor IAccessControlService */
    IAccessControlService::~IAccessControlService()
    {
    #if VERBOSE
      printf( "[Destruindo objeto IAccessControlService (%p)...]\n", this ) ;
    #endif
      delete registryService ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( LuaVM, -1 ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_pushnil( LuaVM ) ;
    lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Objeto IAccessControlService(%p) destruido!]\n\n", this ) ;
    #endif
    }

    bool IAccessControlService::renewLease ( Credential* aCredential, Lease* aLease )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[IAccessControlService::renewLease() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "renewLease" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:renewLease empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_newtable( LuaVM ) ;
      lua_pushstring( LuaVM, "identifier" ) ;
      lua_pushstring( LuaVM, aCredential->identifier ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_pushstring( LuaVM, "owner" ) ;
      lua_pushstring( LuaVM, aCredential->owner ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_pushstring( LuaVM, "delegate" ) ;
      lua_pushstring( LuaVM, aCredential->delegate ) ;
      lua_settable( LuaVM, -3 ) ;
    #if VERBOSE
      printf( "\t[parametro aCredential empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[chamando metodo]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 2, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::renewLease() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      *aLease = (Lease) lua_tonumber( LuaVM, -1 ) ;
    #if VERBOSE
      printf( "\t[resultado aLease retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      returnValue = lua_toboolean( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 2 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::renewLease() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::loginByPassword ( String name, String password, Credential* aCredential, Lease* aLease )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[IAccessControlService::loginByPassword() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "loginByPassword" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:loginByPassword empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, name ) ;
    #if VERBOSE
      printf( "\t[parametro name=%s empilhado]\n", name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, password ) ;
    #if VERBOSE
      printf( "\t[parametro password=%s empilhado]\n", password ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 4, 3, 0 ) != 0 ) {
    #if VERBOSE
      printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::loginByPassword() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -3 ) ) ) ;
      #endif
      *aLease = (Lease) lua_tonumber( LuaVM, -1 ) ;
    #if VERBOSE
      printf( "\t[resultado aLease retirado=%d]\n", (int) *aLease ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
      lua_getfield( LuaVM, -1, "identifier" ) ;
      aCredential->identifier = lua_tostring( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
      lua_getfield( LuaVM, -1, "owner" ) ;
      aCredential->owner = lua_tostring( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
      lua_getfield( LuaVM, -1, "delegate" ) ;
      aCredential->delegate = lua_tostring( LuaVM, -1 ) ;
    #if VERBOSE
      printf( "\t[resultado aCredential retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      returnValue = lua_toboolean( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 3 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::loginByPassword() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::loginByCertificate ( String name, const char* answer, \
        Credential* aCredential, Lease* aLease )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[IAccessControlService::loginByCertificate() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "loginByCertificate" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:loginByCertificate empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, name ) ;
    #if VERBOSE
      printf( "\t[parametro name=%s empilhado]\n", name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( LuaVM, (void*) answer ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[parametro answer empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 4, 3, 0 ) != 0 ) {
    #if VERBOSE
      printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::loginByCertificate() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -3 ) ) ) ;
      #endif
      *aLease = (Lease) lua_tonumber( LuaVM, -1 ) ;
    #if VERBOSE
      printf( "\t[resultado aLease retirado=%d]\n", (int) *aLease ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
      lua_getfield( LuaVM, -1, "identifier" ) ;
      aCredential->identifier = lua_tostring( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
      lua_getfield( LuaVM, -1, "owner" ) ;
      aCredential->owner = lua_tostring( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
      lua_getfield( LuaVM, -1, "delegate" ) ;
      aCredential->delegate = lua_tostring( LuaVM, -1 ) ;
    #if VERBOSE
      printf( "\t[resultado aCredential retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      returnValue = lua_toboolean( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 3 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::loginByCertificate() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    const char* IAccessControlService::getChallenge ( String name )
    {
      char* returnValue ;
    #if VERBOSE
      printf( "[IAccessControlService::getChallenge() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "getChallenge" ) ;
    #if VERBOSE
      printf( "\t[metodo acs:getChallenge empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_insert( LuaVM, -2 ) ;
      lua_pushstring( LuaVM, name ) ;
    #if VERBOSE
      printf( "\t[parametro name=%s empilhado]\n", name ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::getChallenge() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
    /* delete por conta do usuario?? */
      returnValue = new char ;
      lua_pushlightuserdata( LuaVM, returnValue ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::getChallenge() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::logout ( Credential* aCredential )
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::logout() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "logout" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:logout empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_newtable( LuaVM ) ;
      lua_pushstring( LuaVM, "identifier" ) ;
      lua_pushstring( LuaVM, aCredential->identifier ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_pushstring( LuaVM, "owner" ) ;
      lua_pushstring( LuaVM, aCredential->owner ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_pushstring( LuaVM, "delegate" ) ;
      lua_pushstring( LuaVM, aCredential->delegate ) ;
      lua_settable( LuaVM, -3 ) ;
    #if VERBOSE
      printf( "\t[parametro aCredential empilhado\n\t\tidentifier:%s\n\t\towner:%s\n\t\tdelegate:%s]\n",
          aCredential->identifier, aCredential->owner, aCredential->delegate ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "\t[chamando metodo]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::logout() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IAccessControlService::logout() FIM]\n\n" ) ;
  #endif
      return returnValue ;
    }

    bool IAccessControlService::isValid ( Credential* aCredential )
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::isValid() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, "isValid" ) ;
      lua_gettable( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:isValid empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_insert( LuaVM, -2 ) ;
      lua_newtable( LuaVM ) ;
      lua_pushstring( LuaVM, "identifier" ) ;
      lua_pushstring( LuaVM, aCredential->identifier ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_pushstring( LuaVM, "owner" ) ;
      lua_pushstring( LuaVM, aCredential->owner ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_pushstring( LuaVM, "delegate" ) ;
      lua_pushstring( LuaVM, aCredential->delegate ) ;
      lua_settable( LuaVM, -3 ) ;
      lua_setglobal( LuaVM , "aCredential" ) ;
      lua_getglobal( LuaVM, "aCredential" ) ;
    #if VERBOSE
      printf( "\t[parametro aCredential empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::isValid() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::isValid() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    IRegistryService* IAccessControlService::getRegistryService()
    {
    #if VERBOSE
      printf( "[IAccessControlService::getRegistryService() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "getRegistryService" ) ;
    #if VERBOSE
      printf( "\t[metodo acs:getRegistryService empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_insert( LuaVM, -2 ) ;
      if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::isValid() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      if ( registryService == NULL )
      {
        registryService = new IRegistryService ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( LuaVM, registryService ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IRegistryService Lua:%p C:%p]\n", ptr, registryService ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::getRegistryService() FIM]\n\n" ) ;
    #endif
      return registryService ;
    }

    CredentialObserverIdentifier IAccessControlService::addObserver( ICredentialObserver*
observer, CredentialIdentifierList* someCredentialIdentifiers )
    {
      char* returnValue;
      size_t size ;
    #if VERBOSE
      printf( "[IAccessControlService::addObserver() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "addObserver" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:addObserver empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( LuaVM, observer ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[parametro observer]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_newtable( LuaVM ) ;
      if ( someCredentialIdentifiers != NULL )
      {
        luaidl::cpp::types::String str ;
      #if VERBOSE
        printf( "\t[Criando objeto someCredentialIdentifiers length=%d]\n", \
            someCredentialIdentifiers->length() ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      #endif
        for ( int y = 0; y < someCredentialIdentifiers->length(); y++ )
        {
          str = someCredentialIdentifiers->getmember( y ) ;
          lua_pushnumber( LuaVM, y + 1 ) ;
          lua_pushstring( LuaVM, str ) ;
          lua_settable( LuaVM, -3 ) ;
        #if VERBOSE
          printf( "\t[Criando objeto someCredentialIdentifiers[%d] = %s]\n", \
              y, str ) ;
          printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        #endif
        }
      } /* if */
    #if VERBOSE
      printf( "\t[parametro someCredentialIdentifiers empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::addObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      const char * luastring = lua_tolstring( LuaVM, -1, &size ) ;
      returnValue = new char[ size + 1 ] ;
      memcpy( returnValue, luastring, size ) ;
      returnValue[ size ] = '\0' ;
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[retornando = %s]\n", returnValue ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::removeObserver( CredentialObserverIdentifier identifier )
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::removeObserver() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "removeObserver" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:removeObserver empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, identifier ) ;
    #if VERBOSE
      printf( "\t[parametro CredentialObserverIdentifier=%s empilhado]\n", identifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::removeObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::removeObserver() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::addCredentialToObserver ( CredentialObserverIdentifier observerIdentifier, \
        CredentialIdentifier CredentialIdentifier )
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::addCredentialToObserver() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Chamando remotamente: %s( %s , %s)]\n", \
          "addCredentialToObserver", observerIdentifier, CredentialIdentifier ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "addCredentialToObserver" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:addCredentialToObserver empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, observerIdentifier ) ;
    #if VERBOSE
      printf( "\t[parametro observerIdentifier=%s empilhado]\n", observerIdentifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, CredentialIdentifier ) ;
    #if VERBOSE
      printf( "\t[parametro CredentialIdentifier=%s empilhado]\n", CredentialIdentifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::addCredentialToObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::addCredentialToObserver() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::removeCredentialFromObserver ( CredentialObserverIdentifier \
        observerIdentifier, CredentialIdentifier CredentialIdentifier)
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::removeCredentialFromObserver() COMECO]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getglobal( LuaVM, "invoke" ) ;
      lua_pushlightuserdata( LuaVM, this ) ;
      lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "\t[IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( LuaVM, -1 ), this ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_getfield( LuaVM, -1, "removeCredentialFromObserver" ) ;
      lua_insert( LuaVM, -2 ) ;
    #if VERBOSE
      printf( "\t[metodo acs:removeCredentialFromObserver empilhado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, observerIdentifier ) ;
    #if VERBOSE
      printf( "\t[parametro observerIdentifier=%s empilhado]\n", observerIdentifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pushstring( LuaVM, CredentialIdentifier ) ;
    #if VERBOSE
      printf( "\t[parametro CredentialIdentifier=%s empilhado]\n", CredentialIdentifier ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      if ( lua_pcall( LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( LuaVM, "tostring" ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_pcall( LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( LuaVM, -1 ) ;
        lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[lancando excecao]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IAccessControlService::removeCredentialFromObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[resultado do metodo retirado]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    #endif
      lua_pop( LuaVM, 1 ) ;
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "[IAccessControlService::removeCredentialFromObserver() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }



  }
}

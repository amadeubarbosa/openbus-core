/*
* services/IAccessControlService.cpp
*/

#include <services/IAccessControlService.h>
#include <string.h>
#include <lua.hpp>

namespace openbus {
  namespace services {

    ICredentialObserver::ICredentialObserver()
    {
    #if VERBOSE
      printf( "[ICredentialObserver::ICredentialObserver() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando objeto ICredentialObserver]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_getfield( Openbus::LuaVM, -1, "newservant" ) ;
      lua_newtable( Openbus::LuaVM ) ;
      ptr_luaimpl = (void*) lua_topointer( Openbus::LuaVM, -1 ) ;
      lua_pushvalue( Openbus::LuaVM, -1 ) ;
    #if VERBOSE
      printf( "  [Objeto Lua ICredentialObserver criado (%p)]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
    #endif
    /* Cria uma referencia para o objeto C++ atraves do objeto em Lua.
    *  Esta referencia sera utilizada pelo metodo _credentialWasDeleted_bind com o intuito
    *  do mesmo saber a qual objeto ICredentialObserver a chamata ao metodo credentialWasDeleted
    *  deve ser passada.
    */
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      lua_pushstring( Openbus::LuaVM, "credentialWasDeleted" ) ;
      lua_pushcfunction( Openbus::LuaVM, ICredentialObserver::_credentialWasDeleted_bind ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
      lua_pushstring( Openbus::LuaVM, "IDL:openbusidl/acs/ICredentialObserver:1.0" ) ;
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
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [ICredentialObserver Lua:%p C:%p]\n", \
        ptr, this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[ICredentialObserver::ICredentialObserver() FIM]\n\n" ) ;
    #endif
    }

    ICredentialObserver::~ICredentialObserver()
    {
    #if VERBOSE
      printf( "[Destruindo objeto ICredentialObserver (%p)...]\n", this ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
      printf( "[Liberando referencia Lua:%p]\n", lua_topointer( Openbus::LuaVM, -1 ) ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #endif
    lua_pushlightuserdata( Openbus::LuaVM, this ) ;
    lua_pushnil( Openbus::LuaVM ) ;
    lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Liberando referencia Lua da implementacao:%p]\n", ptr_luaimpl ) ;
    #endif
    lua_pushlightuserdata( Openbus::LuaVM, ptr_luaimpl ) ;
    lua_pushnil( Openbus::LuaVM ) ;
    lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "[Objeto ICredentialObserver(%p) destruido!]\n\n", this ) ;
    #endif
    }

    int ICredentialObserver::_credentialWasDeleted_bind ( Lua_State* L )
    {
      size_t size ;
      char* str ;
    #if VERBOSE
      printf( "  [ICredentialObserver::_credentialWasDeleted_bind() COMECO]\n" ) ;
      printf( "    [Tamanho da pilha de Lua: %d]\n" , lua_gettop( L ) ) ;
    #endif
      lua_insert( L, 1 ) ;
      lua_gettable( L, LUA_REGISTRYINDEX ) ;
      ICredentialObserver* co = (ICredentialObserver*) lua_topointer( L, -1 ) ;
    #if VERBOSE
      printf( "    [ICredentialObserver C++: %p]\n" , co ) ;
    #endif
      lua_pop( L, 1 ) ;
    #if VERBOSE
      printf( "    [Criando objeto Credential...]\n" ) ;
    #endif
    /* quem faz delete desse cara?? */
      Credential* c = new Credential ;
      lua_getfield( L, -1, "entityName" ) ;
      const char * luastring = lua_tolstring( L, -1, &size ) ;
      str = new char[ size + 1 ] ;
      memcpy( str, luastring, size ) ;
      str[ size ] = '\0' ;
      c->entityName = str ;
    #if VERBOSE
      printf( "    [credential->entityName=%s]\n", c->entityName ) ;
    #endif
      lua_pop( L, 1 ) ;
      lua_getfield( L, -1, "identifier" ) ;
      luastring = lua_tolstring( L, -1, &size ) ;
      str = new char[ size + 1 ] ;
      memcpy( str, luastring, size ) ;
      str[ size ] = '\0' ;
      c->identifier = str ;
    #if VERBOSE
      printf( "    [credential->identifier=%s]\n",  c->identifier ) ;
    #endif
      lua_pop( L, 2 ) ;
      co->credentialWasDeleted( c ) ;
    #if VERBOSE
      printf( "    [Tamanho da pilha de Lua: %d]\n" , lua_gettop( L ) ) ;
      printf( "  [ICredentialObserver::_credentialWasDeleted_bind() FIM]\n\n" ) ;
    #endif
      return 0 ;
    }

    IAccessControlService::IAccessControlService ( String reference, String interface )
    {
      registryService = NULL ;
    #if VERBOSE
      printf( "[IAccessControlService::IAccessControlService() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Criando proxy para IAccessControlService]\n" ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "oil" ) ;
      lua_getfield( Openbus::LuaVM, -1, "newproxy" ) ;
      lua_pushstring( Openbus::LuaVM, reference ) ;
    #if VERBOSE
      printf( "  [parametro reference=%s empilhado]\n", reference ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, interface ) ;
    #if VERBOSE
      printf( "  [parametro interface=%s empilhado]\n", interface ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
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
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", ptr, this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
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
      printf( "[Objeto IAccessControlService(%p) destruido!]\n\n", this ) ;
    #endif
    }

    bool IAccessControlService::renewLease ( Credential* aCredential, Lease* aLease )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[IAccessControlService::renewLease() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "renewLease" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:renewLease empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      lua_pushstring( Openbus::LuaVM, "identifier" ) ;
      lua_pushstring( Openbus::LuaVM, aCredential->identifier ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
      lua_pushstring( Openbus::LuaVM, "entityName" ) ;
      lua_pushstring( Openbus::LuaVM, aCredential->entityName ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
    #if VERBOSE
      printf( "  [parametro aCredential empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "  [chamando metodo]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 2, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::renewLease() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      *aLease = (Lease) lua_tonumber( Openbus::LuaVM, -1 ) ;
    #if VERBOSE
      printf( "  [resultado aLease retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      returnValue = lua_toboolean( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 2 ) ;
  #if VERBOSE
    printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    printf( "[IAccessControlService::renewLease() FIM]\n\n" ) ;
  #endif
      return returnValue ;
    }

    bool IAccessControlService::loginByPassword ( String name, String password, Credential* aCredential, Lease* aLease )
    {
      bool returnValue ;
    #if VERBOSE
      printf( "[IAccessControlService::loginByPassword() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "loginByPassword" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:loginByPassword empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "  [parametro name=%s empilhado]\n", name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, password ) ;
    #if VERBOSE
      printf( "  [parametro password=%s empilhado]\n", password ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 4, 3, 0 ) != 0 ) {
    #if VERBOSE
      printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::loginByPassword() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      #if VERBOSE
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -3 ) ) ) ;
      #endif
      *aLease = (Lease) lua_tonumber( Openbus::LuaVM, -1 ) ;
    #if VERBOSE
      printf( "  [resultado aLease retirado=%d]\n", (int) *aLease ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
      lua_getfield( Openbus::LuaVM, -1, "identifier" ) ;
      aCredential->identifier = lua_tostring( Openbus::LuaVM, -1 ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
      lua_getfield( Openbus::LuaVM, -1, "entityName" ) ;
      aCredential->entityName = lua_tostring( Openbus::LuaVM, -1 ) ;
    #if VERBOSE
      printf( "  [resultado aCredential retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      returnValue = lua_toboolean( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 3 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
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
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "loginByCertificate" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:loginByCertificate empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "  [parametro name=%s empilhado]\n", name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, (void*) answer ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [parametro answer empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 4, 3, 0 ) != 0 ) {
    #if VERBOSE
      printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
    #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::loginByCertificate() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      #if VERBOSE
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -3 ) ) ) ;
      #endif
      *aLease = (Lease) lua_tonumber( Openbus::LuaVM, -1 ) ;
    #if VERBOSE
      printf( "  [resultado aLease retirado=%d]\n", (int) *aLease ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
      lua_getfield( Openbus::LuaVM, -1, "identifier" ) ;
      aCredential->identifier = lua_tostring( Openbus::LuaVM, -1 ) ;
      lua_pop( Openbus::LuaVM, 1 ) ;
      lua_getfield( Openbus::LuaVM, -1, "entityName" ) ;
      aCredential->entityName = lua_tostring( Openbus::LuaVM, -1 ) ;
    #if VERBOSE
      printf( "  [resultado aCredential retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      returnValue = lua_toboolean( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 3 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IAccessControlService::loginByCertificate() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    const char* IAccessControlService::getChallenge ( String name )
    {
      char* returnValue ;
    #if VERBOSE
      printf( "[IAccessControlService::getChallenge() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "getChallenge" ) ;
    #if VERBOSE
      printf( "  [metodo acs:getChallenge empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_pushstring( Openbus::LuaVM, name ) ;
    #if VERBOSE
      printf( "  [parametro name=%s empilhado]\n", name ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::getChallenge() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
    /* delete por conta do usuario?? */
      returnValue = new char ;
      lua_pushlightuserdata( Openbus::LuaVM, returnValue ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IAccessControlService::getChallenge() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::logout ( Credential* aCredential )
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::logout() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "logout" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:logout empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      lua_pushstring( Openbus::LuaVM, "identifier" ) ;
      lua_pushstring( Openbus::LuaVM, aCredential->identifier ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
      lua_pushstring( Openbus::LuaVM, "entityName" ) ;
      lua_pushstring( Openbus::LuaVM, aCredential->entityName ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
    #if VERBOSE
      printf( "  [parametro aCredential empilhado\nidentifier:%s\nentityName:%s]\n",
          aCredential->identifier, aCredential->entityName ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "  [chamando metodo]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::logout() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
  #if VERBOSE
    printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    printf( "[IAccessControlService::logout() FIM]\n\n" ) ;
  #endif
      return returnValue ;
    }

    bool IAccessControlService::isValid ( Credential* aCredential )
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::isValid() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, "isValid" ) ;
      lua_gettable( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:isValid empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_newtable( Openbus::LuaVM ) ;
      lua_pushstring( Openbus::LuaVM, "identifier" ) ;
      lua_pushstring( Openbus::LuaVM, aCredential->identifier ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
      lua_pushstring( Openbus::LuaVM, "entityName" ) ;
      lua_pushstring( Openbus::LuaVM, aCredential->entityName ) ;
      lua_settable( Openbus::LuaVM, -3 ) ;
      lua_setglobal( Openbus::LuaVM , "aCredential" ) ;
      lua_getglobal( Openbus::LuaVM, "aCredential" ) ;
    #if VERBOSE
      printf( "  [parametro aCredential empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::isValid() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IAccessControlService::isValid() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

    IRegistryService* IAccessControlService::getRegistryService()
    {
    #if VERBOSE
      printf( "[IAccessControlService::getRegistryService() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "getRegistryService" ) ;
    #if VERBOSE
      printf( "  [metodo acs:getRegistryService empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_insert( Openbus::LuaVM, -2 ) ;
      if ( lua_pcall( Openbus::LuaVM, 2, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::isValid() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      if ( registryService == NULL )
      {
        registryService = new IRegistryService ;
      } /* if */
    #if VERBOSE
      const void* ptr = lua_topointer( Openbus::LuaVM, -1 ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, registryService ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
      lua_settable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IRegistryService Lua:%p C:%p]\n", ptr, registryService ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
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
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "addObserver" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:addObserver empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushlightuserdata( Openbus::LuaVM, observer ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [parametro observer]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_newtable( Openbus::LuaVM ) ;
      if ( someCredentialIdentifiers != NULL )
      {
        luaidl::cpp::types::String str ;
      #if VERBOSE
        printf( "  [Criando objeto someCredentialIdentifiers length=%d]\n", \
            someCredentialIdentifiers->length() ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      #endif
        for ( int y = 0; y < someCredentialIdentifiers->length(); y++ )
        {
          str = someCredentialIdentifiers->getmember( y ) ;
          lua_pushnumber( Openbus::LuaVM, y + 1 ) ;
          lua_pushstring( Openbus::LuaVM, str ) ;
          lua_settable( Openbus::LuaVM, -3 ) ;
        #if VERBOSE
          printf( "  [Criando objeto someCredentialIdentifiers[%d] = %s]\n", \
              y, str ) ;
          printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        #endif
        }
      } /* if */
    #if VERBOSE
      printf( "  [parametro someCredentialIdentifiers empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::addObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      const char * luastring = lua_tolstring( Openbus::LuaVM, -1, &size ) ;
      returnValue = new char[ size + 1 ] ;
      memcpy( returnValue, luastring, size ) ;
      returnValue[ size ] = '\0' ;
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [retornando = %s]\n", returnValue ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      return returnValue ;
    }

    bool IAccessControlService::removeObserver( CredentialObserverIdentifier identifier )
    {
      bool returnValue;
    #if VERBOSE
      printf( "[IAccessControlService::removeObserver() COMECO]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "removeObserver" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:removeObserver empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, identifier ) ;
    #if VERBOSE
      printf( "  [parametro CredentialObserverIdentifier=%s empilhado]\n", identifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 3, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::removeObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
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
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "  [Chamando remotamente: %s( %s , %s)]\n", \
          "addCredentialToObserver", observerIdentifier, CredentialIdentifier ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "addCredentialToObserver" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:addCredentialToObserver empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, observerIdentifier ) ;
    #if VERBOSE
      printf( "  [parametro observerIdentifier=%s empilhado]\n", observerIdentifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, CredentialIdentifier ) ;
    #if VERBOSE
      printf( "  [parametro CredentialIdentifier=%s empilhado]\n", CredentialIdentifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::addCredentialToObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
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
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getglobal( Openbus::LuaVM, "invoke" ) ;
      lua_pushlightuserdata( Openbus::LuaVM, this ) ;
      lua_gettable( Openbus::LuaVM, LUA_REGISTRYINDEX ) ;
    #if VERBOSE
      printf( "  [IAccessControlService Lua:%p C:%p]\n", \
        lua_topointer( Openbus::LuaVM, -1 ), this ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_getfield( Openbus::LuaVM, -1, "removeCredentialFromObserver" ) ;
      lua_insert( Openbus::LuaVM, -2 ) ;
    #if VERBOSE
      printf( "  [metodo acs:removeCredentialFromObserver empilhado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, observerIdentifier ) ;
    #if VERBOSE
      printf( "  [parametro observerIdentifier=%s empilhado]\n", observerIdentifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pushstring( Openbus::LuaVM, CredentialIdentifier ) ;
    #if VERBOSE
      printf( "  [parametro CredentialIdentifier=%s empilhado]\n", CredentialIdentifier ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      if ( lua_pcall( Openbus::LuaVM, 4, 1, 0 ) != 0 ) {
      #if VERBOSE
        printf( "  [ERRO ao realizar pcall do metodo]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "  [Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( Openbus::LuaVM, lua_type( Openbus::LuaVM, -1 ) ) ) ;
      #endif
        const char * errmsg ;
        lua_getglobal( Openbus::LuaVM, "tostring" ) ;
        lua_insert( Openbus::LuaVM, -2 ) ;
        lua_pcall( Openbus::LuaVM, 1, 1, 0 ) ;
        errmsg = lua_tostring( Openbus::LuaVM, -1 ) ;
        lua_pop( Openbus::LuaVM, 1 ) ;
      #if VERBOSE
        printf( "  [lancando excecao]\n" ) ;
        printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
        printf( "[IAccessControlService::removeCredentialFromObserver() FIM]\n\n" ) ;
      #endif
        throw errmsg ;
      } /* if */
      returnValue = lua_toboolean( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [resultado do metodo retirado]\n" ) ;
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
    #endif
      lua_pop( Openbus::LuaVM, 1 ) ;
    #if VERBOSE
      printf( "  [Tamanho da pilha de Lua: %d]\n" , lua_gettop( Openbus::LuaVM ) ) ;
      printf( "[IAccessControlService::removeCredentialFromObserver() FIM]\n\n" ) ;
    #endif
      return returnValue ;
    }

  }
}

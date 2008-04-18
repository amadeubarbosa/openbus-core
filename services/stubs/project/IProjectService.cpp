/*
** IProjectService.cpp
*/

#include <iostream>
#include "IProjectService.h"
#include <openbus.h>

using namespace openbus ;
using namespace std ;

namespace projectService {

  static lua_State* LuaVM ;

  IProjectService::IProjectService() {
    Openbus* openbus = Openbus::getInstance();
    LuaVM = openbus->getLuaVM() ;
  #if VERBOSE
    printf( "[IProjectService::IProjectService () COMECO]\n" ) ;
    printf( "\t[This: %p]\n", this ) ;
/*    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Criando proxy para IProjectService]\n" ) ;*/
  #endif
/*    lua_getglobal( LuaVM, "oil" ) ;
    lua_getfield( LuaVM, -1, "newproxy" ) ;
    lua_pushstring( LuaVM, "IDL:openbusidl/ps/IProjectService:1.0" ) ;*/
//     if ( lua_pcall( LuaVM, 1, 1, 0 ) != 0 ) {
//       const char * returnValue ;
//       lua_getglobal( LuaVM, "tostring" ) ;
//       lua_insert( LuaVM, -2 ) ;
//       lua_pcall( LuaVM, 1, 1, 0 ) ;
//       returnValue = lua_tostring( LuaVM, -1 ) ;
//       lua_pop( LuaVM, 1 ) ;
//       throw returnValue ;
//     } /* if */
  #if VERBOSE
/*    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;*/
    printf( "[IProjectService::IProjectService() FIM]\n\n" ) ;
  #endif
  }

  IProjectService::~IProjectService() {

  }

  ProjectList* IProjectService::getProjects() {
    ProjectList* returnValue = NULL ;
  #if VERBOSE
    printf( "[(%p)IProjectService::getProjects() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProjectService Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getProjects" ) ;
  #if VERBOSE
    printf( "\t[metodo getProjects empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IProjectService::getProjects() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
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
        printf( "\t[gerando valor de retorno do tipo ProjectList]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      #endif
          returnValue = new ProjectList( 256 ) ;
        } /* if */
        IProject* project = new IProject ;
      #if VERBOSE
        printf( "\t[ProjectList[%d]] C++: %p\n", x, project ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n",lua_gettop( LuaVM ) ) ;
      #endif
        lua_pushlightuserdata( LuaVM, project ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
//         lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[ProjectList[%d] desempilhada]\n", x ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      #endif
        returnValue->newmember( project ) ;
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
    printf( "[IProjectService::getProjects() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  IProject* IProjectService::getProject ( char* name ) {
    IProject* returnValue = NULL ;
  #if VERBOSE
    printf( "[(%p)IProjectService::getProject() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProjectService Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getProject" ) ;
  #if VERBOSE
    printf( "\t[metodo getProject empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushstring( LuaVM, name ) ;
  #if VERBOSE
    printf( "\t[parâmetro name=%s empilhado]\n", name ) ;
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
      printf( "[IProjectService::getProject() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = new IProject ;
    lua_pushlightuserdata( LuaVM, returnValue ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProjectService::getProject() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  IFile* IProjectService::getFile( const char* path ) {
    IFile* returnValue = NULL ;
  #if VERBOSE
    printf( "[(%p)IProjectService::getFile() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProjectService Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getFile" ) ;
  #if VERBOSE
    printf( "\t[metodo getFile empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushstring( LuaVM, path ) ;
  #if VERBOSE
    printf( "\t[parâmetro path=%s empilhado]\n", path ) ;
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
      printf( "[IProjectService::getFile() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = new IFile ;
    lua_pushlightuserdata( LuaVM, returnValue ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProjectService::getFile() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  IProject* IProjectService::createProject( char* name ) {
    IProject* returnValue = NULL ;
  #if VERBOSE
    printf( "[(%p)IProjectService::createProject() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProjectService Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "createProject" ) ;
  #if VERBOSE
    printf( "\t[metodo createProject empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushstring( LuaVM, name ) ;
  #if VERBOSE
    printf( "\t[parâmetro name=%s empilhado]\n", name ) ;
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
      printf( "[IProjectService::createProject() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = new IProject ;
    lua_pushlightuserdata( LuaVM, returnValue ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProjectService::createProject() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IProjectService::deleteProject( IProject* aProject) {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IProjectService::deleteProject() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProjectService Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "deleteProject" ) ;
  #if VERBOSE
    printf( "\t[metodo deleteProject empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushlightuserdata( LuaVM, aProject ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[parâmetro aProject=%p empilhado]\n", aProject ) ;
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
      printf( "[IProjectService::deleteProject() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProjectService::deleteProject() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  IProject::IProject() {
  #if VERBOSE
    printf( "[IProject::IProject () COMECO]\n" ) ;
    printf( "\t[This: %p]\n", this ) ;
  #endif

  #if VERBOSE
    printf( "[IProject::IProject() FIM]\n\n" ) ;
  #endif
  }

  IProject::~IProject() {

  }

  IFile::IFile() {
  #if VERBOSE
    printf( "[IFile::IFile () COMECO]\n" ) ;
    printf( "\t[This: %p]\n", this ) ;
  #endif

  #if VERBOSE
/*    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;*/
    printf( "[IFile::IFile() FIM]\n\n" ) ;
  #endif
  }

  IFile::~IFile() {

  }

  luaidl::cpp::types::String IFile::getName() {
    char* returnValue = NULL ;
    size_t size ;
  #if VERBOSE
    printf( "[(%p)IFile::getName() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getName" ) ;
  #if VERBOSE
    printf( "\t[metodo getName empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::getName() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    const char * luastring = lua_tolstring( LuaVM, -1, &size ) ;
    returnValue = new char[ size + 1 ] ;
    memcpy( returnValue, luastring, size ) ;
    returnValue[ size ] = '\0' ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::getName() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  char* IFile::getPath() {
    char* returnValue = NULL ;
    size_t size ;
  #if VERBOSE
    printf( "[(%p)IFile::getPath() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getPath" ) ;
  #if VERBOSE
    printf( "\t[metodo getPath empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::getPath() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    const char * luastring = lua_tolstring( LuaVM, -1, &size ) ;
    returnValue = new char[ size + 1 ] ;
    memcpy( returnValue, luastring, size ) ;
    returnValue[ size ] = '\0' ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::getPath() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  long long IFile::getSize() {
    long long returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::getSize() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getPath" ) ;
  #if VERBOSE
    printf( "\t[metodo getSize empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::getPath() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    returnValue = lua_tointeger( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::getSize() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::canRead() {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::canRead() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "canRead" ) ;
  #if VERBOSE
    printf( "\t[metodo canRead empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::canRead() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::canRead() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::canWrite() {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::canWrite() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "canWrite" ) ;
  #if VERBOSE
    printf( "\t[metodo canWrite empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::canWrite() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::canWrite() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::isDirectory() {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::isDirectory() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "isDirectory" ) ;
  #if VERBOSE
    printf( "\t[metodo isDirectory empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::isDirectory() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::isDirectory() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  FileList* IFile::getFiles() {
    FileList* returnValue = NULL ;
  #if VERBOSE
    printf( "[(%p)IFile::getFiles() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getFiles" ) ;
  #if VERBOSE
    printf( "\t[metodo getFiles empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::getFiles() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    for ( int x = 1; ; x++ )
    {
      lua_pushnumber( LuaVM, x ) ;
      lua_gettable( LuaVM, -2 ) ;
      if ( !lua_istable( LuaVM, -1 ) )
      {
      #if VERBOSE
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
      #endif
        break ;
      } else {
        if ( x == 1 )
        {
      #if VERBOSE
        printf( "\t[gerando valor de retorno do tipo FileList]\n" ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      #endif
          returnValue = new FileList( 256 ) ;
        } /* if */
        IFile* file = new IFile ;
      #if VERBOSE
        printf( "\t[FileList[%d]] C++: %p\n", x, file ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n",lua_gettop( LuaVM ) ) ;
      #endif
        lua_pushlightuserdata( LuaVM, file ) ;
        lua_insert( LuaVM, -2 ) ;
        lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
//         lua_pop( LuaVM, 1 ) ;
      #if VERBOSE
        printf( "\t[FileList[%d] desempilhada]\n", x ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      #endif
        returnValue->newmember( file ) ;
      #if VERBOSE
        printf( "\t[FileList[%d] criado...]\n", x ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      #endif
      } /* if */
    } /* for */
  /* retira indice da pilha e valor de retorno*/
    lua_pop( LuaVM, 2 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::getFiles() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  IProject* IFile::getProject() {
    IProject* returnValue = NULL ;
  #if VERBOSE
    printf( "[(%p)IFile::getProject() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getProject" ) ;
  #if VERBOSE
    printf( "\t[metodo getProject empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::getDataChannel() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = new IProject ;
    lua_pushlightuserdata( LuaVM, returnValue ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::getDataChannel() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::createFile( char* name, char* type ) {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::createFile() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "createFile" ) ;
  #if VERBOSE
    printf( "\t[metodo createFile empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushstring( LuaVM, name ) ;
  #if VERBOSE
    printf( "\t[parâmetro name=%s empilhado]\n", name ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_pushstring( LuaVM, type ) ;
  #if VERBOSE
    printf( "\t[parâmetro type=%s empilhado]\n", type ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
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
      printf( "[IFile::createFile() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::createFile() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::createDirectory ( char* name ) {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::createDirectory() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "createDirectory" ) ;
  #if VERBOSE
    printf( "\t[metodo createDirectory empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushstring( LuaVM, name ) ;
  #if VERBOSE
    printf( "\t[parâmetro name=%s empilhado]\n", name ) ;
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
      printf( "[IFile::createDirectory() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::createDirectory() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::Delete() {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::Delete() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "delete" ) ;
  #if VERBOSE
    printf( "\t[metodo delete empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::Delete() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::Delete() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::rename ( char* newName ) {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::rename() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "rename" ) ;
  #if VERBOSE
    printf( "\t[metodo rename empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushstring( LuaVM, newName ) ;
  #if VERBOSE
    printf( "\t[parâmetro newName=%s empilhado]\n", newName ) ;
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
      printf( "[IFile::rename() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::rename() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::moveFile( IFile* newParent ) {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::moveFile() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "moveFile" ) ;
  #if VERBOSE
    printf( "\t[metodo moveFile empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushlightuserdata( LuaVM, newParent ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[parâmetro newParent=%p empilhado]\n", newParent ) ;
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
      printf( "[IFile::moveFile() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::moveFile() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  bool IFile::copyFile( IFile* newParent ) {
    bool returnValue ;
  #if VERBOSE
    printf( "[(%p)IFile::copyFile() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "copyFile" ) ;
  #if VERBOSE
    printf( "\t[metodo copyFile empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    lua_pushlightuserdata( LuaVM, newParent ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[parâmetro newParent=%p empilhado]\n", newParent ) ;
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
      printf( "[IFile::copyFile() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::copyFile() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  DataChannel* IFile::getDataChannel() {
    DataChannel* returnValue = NULL ;
    size_t size ;
  #if VERBOSE
    printf( "[(%p)IFile::getDataChannel() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getDataChannel" ) ;
  #if VERBOSE
    printf( "\t[metodo getDataChannel empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IFile::getDataChannel() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    returnValue = new DataChannel ;
  /* DataChannel->host */
  #if VERBOSE
    printf( "\t[Gerando valor de retorno do tipo DataChannel]\n" ) ;
    printf( "\t[DataChannel->host]\n" ) ;
  #endif
    lua_getfield( LuaVM, -1, "host" ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char * luastring = lua_tolstring( LuaVM, -1, &size ) ;
    returnValue->host = new char[ size + 1 ] ;
    memcpy( (void*) returnValue->host, luastring, size ) ;
    returnValue->host[ size ] = '\0' ;
    lua_pop( LuaVM, 1 ) ;
  /* DataChannel->port */
  #if VERBOSE
    printf( "\t[DataChannel->port]\n" ) ;
  #endif
    lua_getfield( LuaVM, -1, "port" ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    returnValue->port = lua_tointeger( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  /* DataChannel->accessKey */
  #if VERBOSE
    printf( "\t[DataChannel->accessKey]\n" ) ;
  #endif
    lua_getfield( LuaVM, -1, "accessKey" ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char* accessKeyStr = lua_tostring( LuaVM, -1 ) ;
    OctetSeq* accessKey  = new OctetSeq ;
    for (size = 0; size < strlen(accessKeyStr); size++ ) {
      accessKey->newmember( (char*) (accessKeyStr + size) ) ;
    }
    returnValue->accessKey = accessKey ;
    lua_pop( LuaVM, 1 ) ;
  /* DataChannel->fileIdentifier */
  #if VERBOSE
    printf( "\t[DataChannel->fileIdentifier]\n" ) ;
  #endif
    lua_getfield( LuaVM, -1, "fileIdentifier" ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    const char* fileIdentifierStr = lua_tostring( LuaVM, -1 ) ;
    OctetSeq* fileIdentifier = new OctetSeq ;
    for (size = 0; size < strlen(fileIdentifierStr); size++ ) {
      fileIdentifier->newmember( (char*) (fileIdentifierStr + size) ) ;
    }
    returnValue->fileIdentifier = fileIdentifier ;
    lua_pop( LuaVM, 1 ) ;
  /* DataChannel->writable */
  #if VERBOSE
    printf( "\t[DataChannel->writable]\n" ) ;
  #endif
    lua_getfield( LuaVM, -1, "writable" ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    returnValue->writable = lua_toboolean( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;
  /* DataChannel->fileSize */
  #if VERBOSE
    printf( "\t[DataChannel->fileSize]\n" ) ;
  #endif
    lua_getfield( LuaVM, -1, "fileSize" ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    returnValue->fileSize = lua_tointeger( LuaVM, -1 ) ;
    lua_pop( LuaVM, 1 ) ;

    lua_pushlightuserdata( LuaVM, returnValue ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::getDataChannel() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  void IFile::close() {
  #if VERBOSE
    printf( "[(%p)IFile::close() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "close" ) ;
  #if VERBOSE
    printf( "\t[metodo close empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 0, 0 ) != 0 ) {
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
      printf( "[IFile::close() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IFile::close() FIM]\n\n" ) ;
  #endif
  }

  luaidl::cpp::types::String IProject::getId() {
    char* returnValue = NULL ;
    size_t size ;
  #if VERBOSE
    printf( "[(%p)IProject::getId() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getId" ) ;
  #if VERBOSE
    printf( "\t[metodo getId empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IProject::getId() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    const char * luastring = lua_tolstring( LuaVM, -1, &size ) ;
    returnValue = new char[ size + 1 ] ;
    memcpy( returnValue, luastring, size ) ;
    returnValue[ size ] = '\0' ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProject::getId() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  luaidl::cpp::types::String IProject::getName() {
    char* returnValue = NULL ;
    size_t size ;
  #if VERBOSE
    printf( "[(%p)IProject::getName() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getName" ) ;
  #if VERBOSE
    printf( "\t[metodo getName empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IProject::getName() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    const char * luastring = lua_tolstring( LuaVM, -1, &size ) ;
    returnValue = new char[ size + 1 ] ;
    memcpy( returnValue, luastring, size ) ;
    returnValue[ size ] = '\0' ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProject::getName() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  luaidl::cpp::types::String IProject::getOwner() {
    char* returnValue = NULL ;
    size_t size ;
  #if VERBOSE
    printf( "[(%p)IProject::getOwner() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getOwner" ) ;
  #if VERBOSE
    printf( "\t[metodo getOwner empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IProject::getOwner() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    const char * luastring = lua_tolstring( LuaVM, -1, &size ) ;
    returnValue = new char[ size + 1 ] ;
    memcpy( returnValue, luastring, size ) ;
    returnValue[ size ] = '\0' ;
    lua_pop( LuaVM, 1 ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProject::getOwner() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  IFile* IProject::getRootFile() {
    IFile* returnValue = NULL ;
  #if VERBOSE
    printf( "[(%p)IProject::getRootFile() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "getRootFile" ) ;
  #if VERBOSE
    printf( "\t[metodo getRootFile empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 1, 0 ) != 0 ) {
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
      printf( "[IProject::getRootFile() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
    #if VERBOSE
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
    #endif
    returnValue = new IFile ;
    lua_pushlightuserdata( LuaVM, returnValue ) ;
    lua_insert( LuaVM, -2 ) ;
    lua_settable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProject::getRootFile() FIM]\n\n" ) ;
  #endif
    return returnValue ;
  }

  void IProject::close() {
  #if VERBOSE
    printf( "[(%p)IProject::close() COMECO]\n", this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n", lua_gettop( LuaVM ) ) ;
  #endif
    lua_getglobal( LuaVM, "invoke" ) ;
    lua_pushlightuserdata( LuaVM, this ) ;
    lua_gettable( LuaVM, LUA_REGISTRYINDEX ) ;
  #if VERBOSE
    printf( "\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer( LuaVM, -1 ), this ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield( LuaVM, -1, "close" ) ;
  #if VERBOSE
    printf( "\t[metodo close empilhado]\n" ) ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename( LuaVM, lua_type( LuaVM, -1 ) ) ) ;
  #endif
    lua_insert( LuaVM, -2 ) ;
    if ( lua_pcall( LuaVM, 2, 0, 0 ) != 0 ) {
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
      printf( "[IProject::close() FIM]\n\n" ) ;
    #endif
      throw returnValue ;
    } /* if */
  #if VERBOSE
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
    printf( "[IProject::close() FIM]\n\n" ) ;
  #endif
  }
}

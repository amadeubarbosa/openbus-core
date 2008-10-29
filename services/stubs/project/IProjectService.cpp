/*
** IProjectService.cpp
*/

#include <iostream>
#include "IProjectService.h"
#include <openbus.h>

using namespace openbus;
using namespace std;

namespace projectService {

  static lua_State* LuaVM = 0;

  IProject::IProject() {
    if (!LuaVM) {
      openbus::Openbus* openbus = openbus::Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
    }
  #if VERBOSE
    printf("[IProject::IProject () COMECO]\n");
    printf("\t[This: %p]\n", this);
  #endif

  #if VERBOSE
    printf("[IProject::IProject() FIM]\n\n");
  #endif
  }

  IProject::~IProject() {

  }

  IFile::IFile() {
    if (!LuaVM) {
      openbus::Openbus* openbus = openbus::Openbus::getInstance();
      LuaVM = openbus->getLuaVM();
    }
  #if VERBOSE
    printf("[IFile::IFile () COMECO]\n");
    printf("\t[This: %p]\n", this);
  #endif

  #if VERBOSE
    printf("[IFile::IFile() FIM]\n\n");
  #endif
  }

  IFile::~IFile() {

  }

  luaidl::cpp::types::String IFile::getName() {
    char* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IFile::getName() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getName");
  #if VERBOSE
    printf("\t[metodo getName empilhado]\n");
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
      printf("[IFile::getName() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
  #if VERBOSE
    printf("\t[gerando valor de retorno do tipo string: %s]\n", luastring);
  #endif
    returnValue = new char[size + 1];
    memcpy(returnValue, luastring, size);
    returnValue[size] = '\0';
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::getName() FIM]\n\n");
  #endif
    return returnValue;
  }

  char* IFile::getPath() {
    char* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IFile::getPath() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getPath");
  #if VERBOSE
    printf("\t[metodo getPath empilhado]\n");
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
      printf("[IFile::getPath() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue = new char[size + 1];
    memcpy(returnValue, luastring, size);
    returnValue[size] = '\0';
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::getPath() FIM]\n\n");
  #endif
    return returnValue;
  }

  long long IFile::getSize() {
    long long returnValue;
  #if VERBOSE
    printf("[(%p)IFile::getSize() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getPath");
  #if VERBOSE
    printf("\t[metodo getSize empilhado]\n");
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
      printf("[IFile::getPath() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    returnValue = lua_tointeger(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::getSize() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::canRead() {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::canRead() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "canRead");
  #if VERBOSE
    printf("\t[metodo canRead empilhado]\n");
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
      printf("[IFile::canRead() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::canRead() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::canWrite() {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::canWrite() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "canWrite");
  #if VERBOSE
    printf("\t[metodo canWrite empilhado]\n");
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
      printf("[IFile::canWrite() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::canWrite() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::isDirectory() {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::isDirectory() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "isDirectory");
  #if VERBOSE
    printf("\t[metodo isDirectory empilhado]\n");
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
      printf("[IFile::isDirectory() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::isDirectory() FIM]\n\n");
  #endif
    return returnValue;
  }

  FileList* IFile::getFiles() {
    FileList* returnValue = NULL;
  #if VERBOSE
    printf("[(%p)IFile::getFiles() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getFiles");
  #if VERBOSE
    printf("\t[metodo getFiles empilhado]\n");
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
      printf("[IFile::getFiles() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    for (int x = 1;; x++)
    {
      lua_pushnumber(LuaVM, x);
      lua_gettable(LuaVM, -2);
      if (!lua_istable(LuaVM, -1))
      {
      #if VERBOSE
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
        printf("\t[Tipo do elemento do TOPO: %s]\n" , \
            lua_typename(LuaVM, lua_type(LuaVM, -1)));
      #endif
        break;
      } else {
        if (x == 1)
        {
      #if VERBOSE
        printf("\t[gerando valor de retorno do tipo FileList]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
          returnValue = new FileList(256);
        } /* if */
        IFile* file = new IFile;
      #if VERBOSE
        printf("\t[FileList[%d]] C++: %p\n", x, file);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pushlightuserdata(LuaVM, file);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);
      #if VERBOSE
        printf("\t[FileList[%d] desempilhada]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
        returnValue->newmember(file);
      #if VERBOSE
        printf("\t[FileList[%d] criado...]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
      } /* if */
    } /* for */
  /* retira indice da pilha e valor de retorno*/
    lua_pop(LuaVM, 2);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::getFiles() FIM]\n\n");
  #endif
    return returnValue;
  }

  IProject* IFile::getProject() {
    IProject* returnValue = NULL;
  #if VERBOSE
    printf("[(%p)IFile::getProject() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getProject");
  #if VERBOSE
    printf("\t[metodo getProject empilhado]\n");
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
      printf("[IFile::getProject() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = new IProject;
    lua_pushlightuserdata(LuaVM, returnValue);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::getProject() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::createFile(char* name, char* type) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::createFile() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "createFile");
  #if VERBOSE
    printf("\t[metodo createFile empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushstring(LuaVM, name);
  #if VERBOSE
    printf("\t[parâmetro name=%s empilhado]\n", name);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_pushstring(LuaVM, type);
  #if VERBOSE
    printf("\t[parâmetro type=%s empilhado]\n", type);
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
      printf("\t[lancando excecao %s]\n", returnValue);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[IFile::createFile() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::createFile() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::createDirectory (char* name) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::createDirectory() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "createDirectory");
  #if VERBOSE
    printf("\t[metodo createDirectory empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushstring(LuaVM, name);
  #if VERBOSE
    printf("\t[parâmetro name=%s empilhado]\n", name);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
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
      printf("[IFile::createDirectory() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::createDirectory() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::Delete() {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::Delete() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "delete");
  #if VERBOSE
    printf("\t[metodo delete empilhado]\n");
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
      printf("[IFile::Delete() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::Delete() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::rename (char* newName) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::rename() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "rename");
  #if VERBOSE
    printf("\t[metodo rename empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushstring(LuaVM, newName);
  #if VERBOSE
    printf("\t[parâmetro newName=%s empilhado]\n", newName);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
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
      printf("[IFile::rename() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::rename() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::moveFile(IFile* newParent) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::moveFile() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "moveFile");
  #if VERBOSE
    printf("\t[metodo moveFile empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, newParent);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro newParent=%p empilhado]\n", newParent);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
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
      printf("[IFile::moveFile() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::moveFile() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IFile::copyFile(IFile* newParent) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IFile::copyFile() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "copyFile");
  #if VERBOSE
    printf("\t[metodo copyFile empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, newParent);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro newParent=%p empilhado]\n", newParent);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
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
      printf("[IFile::copyFile() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::copyFile() FIM]\n\n");
  #endif
    return returnValue;
  }

  void IFile::close() {
  #if VERBOSE
    printf("[(%p)IFile::close() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IFile Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "close");
  #if VERBOSE
    printf("\t[metodo close empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
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
      printf("\t[lancando excecao %s]\n", returnValue);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[IFile::close() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IFile::close() FIM]\n\n");
  #endif
  }

  luaidl::cpp::types::String IProject::getId() {
    char* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IProject::getId() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getId");
  #if VERBOSE
    printf("\t[metodo getId empilhado]\n");
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
      printf("[IProject::getId() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue = new char[size + 1];
    memcpy(returnValue, luastring, size);
    returnValue[size] = '\0';
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IProject::getId() FIM]\n\n");
  #endif
    return returnValue;
  }

  luaidl::cpp::types::String IProject::getName() {
    char* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IProject::getName() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getName");
  #if VERBOSE
    printf("\t[metodo getName empilhado]\n");
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
      printf("[IProject::getName() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
  #if VERBOSE
    printf("\t[gerando valor de retorno do tipo string: %s]\n", luastring);
  #endif
    returnValue = new char[size + 1];
    memcpy(returnValue, luastring, size);
    returnValue[size] = '\0';
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IProject::getName() FIM]\n\n");
  #endif
    return returnValue;
  }

  luaidl::cpp::types::String IProject::getOwner() {
    char* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IProject::getOwner() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getOwner");
  #if VERBOSE
    printf("\t[metodo getOwner empilhado]\n");
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
      printf("[IProject::getOwner() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue = new char[size + 1];
    memcpy(returnValue, luastring, size);
    returnValue[size] = '\0';
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IProject::getOwner() FIM]\n\n");
  #endif
    return returnValue;
  }

  IFile* IProject::getRootFile() {
    IFile* returnValue = NULL;
  #if VERBOSE
    printf("[(%p)IProject::getRootFile() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getRootFile");
  #if VERBOSE
    printf("\t[metodo getRootFile empilhado]\n");
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
      printf("[IProject::getRootFile() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    #if VERBOSE
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename(LuaVM, lua_type(LuaVM, -1)));
    #endif
    returnValue = new IFile;
    lua_pushlightuserdata(LuaVM, returnValue);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IProject::getRootFile() FIM]\n\n");
  #endif
    return returnValue;
  }

  void IProject::close() {
  #if VERBOSE
    printf("[(%p)IProject::close() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IProject Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "close");
  #if VERBOSE
    printf("\t[metodo close empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
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
      printf("\t[lancando excecao %s]\n", returnValue);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("[IProject::close() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IProject::close() FIM]\n\n");
  #endif
  }
}

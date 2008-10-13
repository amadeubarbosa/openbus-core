/*
**  IDataService.cpp
*/

#include "IDataService.h"
#include "../openbus.h"

#include <iostream>
#include <string.h>

namespace dataService {

  static lua_State* LuaVM;

  IDataEntry::IDataEntry() {
    openbus::Openbus* openbus = openbus::Openbus::getInstance();
    LuaVM = openbus->getLuaVM();
  #if VERBOSE
    printf("[IDataEntry::IDataEntry () COMECO]\n");
    printf("\t[This: %p]\n", this);
  #endif
  #if VERBOSE
    printf("[IDataEntry::IDataEntry() FIM]\n\n");
  #endif
  }

  IDataEntry::~IDataEntry() {
  #if VERBOSE
    printf("[IDataEntry::~IDataEntry () COMECO]\n");
  #endif
  #if VERBOSE
    printf("[IDataEntry::~IDataEntry() FIM]\n\n");
  #endif
  }

  DataKey* IDataEntry::getKey() {
    DataKey* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IDataEntry::getKey() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataEntry Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getKey");
  #if VERBOSE
    printf("\t[metodo getKey empilhado]\n");
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
      printf("[IDataEntry::getKey() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = new DataKey;
    lua_getfield(LuaVM, -1, "service_id");
    lua_getfield(LuaVM, -1, "name");
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue->service_id->name = new char[ size + 1 ];
    memcpy(returnValue->service_id->name, luastring, size);
    returnValue->service_id->name[ size ] = '\0';
    lua_pop(LuaVM, 1);

    lua_getfield(LuaVM, -1, "version");
    returnValue->service_id->version = (unsigned long) lua_tonumber(LuaVM, -1);
    lua_pop(LuaVM, 1);
  // link de C++ com Lua para o component_id ??
    lua_pop(LuaVM, 1);
    lua_getfield(LuaVM, -1, "actual_data_id");
    luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue->actual_data_id = new char[ size + 1 ];
    memcpy(returnValue->actual_data_id, luastring, size);
    returnValue->actual_data_id[ size ] = '\0';
    lua_pop(LuaVM, 1);

    lua_pushlightuserdata(LuaVM, returnValue);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::getKey() FIM]\n\n");
  #endif
    return returnValue;
  }

  IDataService* IDataEntry::getDataService() {
    IDataService* returnValue = NULL;
  #if VERBOSE
    printf("[(%p)IDataEntry::getDataService() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataEntry Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getDataService");
  #if VERBOSE
    printf("\t[metodo getDataService empilhado]\n");
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
      printf("[IDataEntry::getDataService() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = new IDataService;
    lua_pushlightuserdata(LuaVM, returnValue);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::getDataService() FIM]\n\n");
  #endif
    return returnValue;
  }

  char* IDataEntry::getFacetInterface() {
    char* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IDataEntry::getFacetInterface() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataEntry Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getFacetInterface");
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
      printf("[IDataEntry::getFacetInterface() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue = new char[ size + 1 ];
    memcpy(returnValue, luastring, size);
    returnValue[ size ] = '\0';
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::getFacetInterface() FIM]\n\n");
  #endif
    return returnValue;
  }

//
// Preciso mapear as exceções OperationNotSupported e UnknownType que são representadas
// através de tabelas Lua, para exceções C++.
//
  void IDataEntry::copyFrom(DataKey* source_key) {
  #if VERBOSE
    printf("[(%p)IDataEntry::copyFrom() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataEntry Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "copyFrom");
  #if VERBOSE
    printf("\t[metodo copyFrom empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, source_key);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro source_key=%p empilhado]\n", source_key);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    if (lua_pcall(LuaVM, 3, 0, 0) != 0) {
      const char* exceptionType = lua_typename(LuaVM, lua_type(LuaVM, -1));
    #if VERBOSE
      printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , exceptionType ) ;
    #endif
      lua_pushvalue(LuaVM, -1);
      const char * errmsg ;
      lua_getglobal( LuaVM, "tostring" ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_pcall( LuaVM, 1, 1, 0 ) ;
      errmsg = lua_tostring( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
      if (strcmp(exceptionType, "table") == 0) {
        const char* repID;
        lua_pushnumber(LuaVM, 1);
        lua_gettable(LuaVM, -2);
        repID = lua_tostring(LuaVM, -1);
        lua_pop(LuaVM, 2) ;
      #if VERBOSE
        printf( "\t[lancando excecao: %s]\n", errmsg ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IDataEntry::copyFrom() FIM]\n\n" ) ;
      #endif
        if (strcmp(repID, "IDL:openbusidl/ds/OperationNotSupported:1.0") == 0) {
          throw new OperationNotSupported;
        } else if (strcmp(repID, "IDL:openbusidl/ds/UnknownType:1.0") == 0) {
          throw new UnknownType;
        } else {
          throw errmsg;
        }
      } else {
      #if VERBOSE
        printf( "\t[lancando excecao: %s]\n", errmsg ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IDataEntry::copyFrom() FIM]\n\n" ) ;
      #endif
        lua_pop(LuaVM, 1);
      }
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::copyFrom() FIM]\n\n");
  #endif
  }

  luaidl::cpp::types::Any* IDataEntry::getAttr(char* attr_name) {
    size_t size;
    luaidl::cpp::types::Any* returnValue = NULL;
  #if VERBOSE
    printf("[(%p)IDataEntry::getAttr() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getAttr");
  #if VERBOSE
    printf("\t[metodo getAttr empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, attr_name);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro key=%p empilhado]\n", attr_name);
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
      printf("[IDataEntry::getAttr() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
  #if VERBOSE
    printf( "\t[gerando valor de retorno do tipo Any]\n") ;
    printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
  #endif
    lua_getfield(LuaVM, -1, "_anytype");
    lua_getfield(LuaVM, -1, "_type");
    const char* _type = lua_tostring(LuaVM, -1);
  #if VERBOSE
    printf( "\t[type: %s]\n", _type ) ;
  #endif
    if (!strcmp(_type, "string")) {
      lua_pop(LuaVM, 2);
      lua_getfield(LuaVM, -1, "_anyval");
      const char * luastring = lua_tolstring(LuaVM, -1, &size);
      char* str = new char[size + 1];
      memcpy(str, luastring, size);
      str[size] = '\0';
    #if VERBOSE
      printf( "\t[value: %s]\n", str ) ;
    #endif
      returnValue = new luaidl::cpp::types::Any;
      *returnValue <<= str;
      lua_pop(LuaVM, 1);
    } else {
      returnValue = NULL;
    }
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::getAttr() FIM]\n\n");
  #endif
    return returnValue;
  }

  ValueList* IDataEntry::getAttrs(scs::core::NameList* attrs_name) {
    ValueList* returnValue = NULL;
  #if VERBOSE
    printf("[(%p)IDataEntry::getAttrs() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getAttrs");
  #if VERBOSE
    printf("\t[metodo getAttrs empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, attrs_name);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro key=%p empilhado]\n", attrs_name);
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
      printf("[IDataEntry::getAttrs() FIM]\n\n");
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
        break;
      } else {
        if (x == 1)
        {
      #if VERBOSE
        printf("\t[gerando valor de retorno do tipo DataList]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
          returnValue = new ValueList(256);
        } /* if */
        luaidl::cpp::types::Any* data = new luaidl::cpp::types::Any;
      #if VERBOSE
        printf("\t[ValueList[%d]] C++: %p\n", x, data);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pushlightuserdata(LuaVM, data);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);
//         lua_pop(LuaVM, 1);
      #if VERBOSE
        printf("\t[ValueList[%d] desempilhada]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
        returnValue->newmember(data);
      #if VERBOSE
        printf("\t[serviceOfferList[%d] criado...]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
      } /* if */
    } /* for */
  /* retira indice da pilha e valor de retorno*/
    lua_pop(LuaVM, 2);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::getAttrs() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IDataEntry::setAttr(char* attr_name, luaidl::cpp::types::Any* attr_value) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IDataEntry::setAttr() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "setAttr");
  #if VERBOSE
    printf("\t[metodo setAttr empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, attr_name);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro attr_name=%p empilhado]\n", attr_name);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    if (attr_value->getTypeCode() == luaidl::cpp::types::tk_string) {
      char* str;
      *attr_value >>= str;
      lua_pushstring(LuaVM, str);
    #if VERBOSE
      printf("\t[parâmetro attr_value=%s empilhado]\n", str);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    #endif
    }
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
      printf("[IDataEntry::setAttr() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::setAttr() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IDataEntry::setAttrs(scs::core::NameList* attrs_name, ValueList* attrs_value) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IDataEntry::setAttrs() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "setAttrs");
  #if VERBOSE
    printf("\t[metodo setAttrs empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, attrs_name);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro attrs_name]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_newtable(LuaVM);
    for (int x = 1; ; x++) {
      lua_pushnumber(LuaVM, x);
      char* name = attrs_name->getmember(x-1);
      lua_pushstring(LuaVM, name);
      lua_settable(LuaVM, -3);
    #if VERBOSE
      printf("\t[namelist[%d]: %s\n", x, name);
      printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
    #endif
    }
  #if VERBOSE
    printf("\t[parâmetro attrs_value]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_newtable(LuaVM);
    for (int x = 1; ; x++) {
      lua_pushnumber(LuaVM, x);
      luaidl::cpp::types::Any* any = attrs_value->getmember(x-1);
      if (any->getTypeCode() == luaidl::cpp::types::tk_string) {
        char* str;
        *any >>= str;
        lua_pushstring(LuaVM, str);
      #if VERBOSE
        printf("\t[parâmetro attr_value=%s empilhado]\n", str);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
      }
      lua_settable(LuaVM, -3);
    #if VERBOSE
      printf("\t[valuelist[%d]\n", x);
      printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
    #endif
    }
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
      printf("[IDataEntry::setAttrs() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataEntry::setAttrs() FIM]\n\n");
  #endif
    return returnValue;
  }

  IDataService::IDataService() {
    openbus::Openbus* openbus = openbus::Openbus::getInstance();
    LuaVM = openbus->getLuaVM();
  #if VERBOSE
    printf("[IDataService::IDataService () COMECO]\n");
    printf("\t[This: %p]\n", this);
  #endif
  #if VERBOSE
    printf("[IDataService::IDataService() FIM]\n\n");
  #endif
  }

  IDataService::~IDataService() {
  #if VERBOSE
    printf("[IDataService::~IDataService () COMECO]\n");
  #endif
  #if VERBOSE
    printf("[IDataService::~IDataService() FIM]\n\n");
  #endif
  }

  DataList* IDataService::getRoots() {
    DataList* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IDataService::getRoots() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getRoots");
  #if VERBOSE
    printf("\t[metodo getRoots empilhado]\n");
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
      printf("[IDataService::getRoots() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
  #if VERBOSE
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    for (int x = 1;; x++)
    {
      lua_pushnumber(LuaVM, x);
      lua_gettable(LuaVM, -2);
      if (!lua_istable(LuaVM, -1))
      {
        break;
      } else {
        if (x == 1)
        {
      #if VERBOSE
        printf("\t[gerando valor de retorno do tipo DataList]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
          returnValue = new DataList(256);
        } /* if */
        Data* data = new Data;
        data->key = new DataKey;
        data->key->service_id = new scs::core::ComponentId;
      #if VERBOSE
        printf("\t[DataList[%d]] C++: %p\n", x, data);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif

        lua_getfield(LuaVM, -1, "key");
        lua_getfield(LuaVM, -1, "service_id");
        lua_getfield(LuaVM, -1, "name");
        const char * luastring = lua_tolstring(LuaVM, -1, &size);
        data->key->service_id->name = new char[ size + 1 ];
        memcpy(data->key->service_id->name, luastring, size);
        data->key->service_id->name[ size ] = '\0';
      #if VERBOSE
        printf("\t[data->key->service_id->name: %s]\n", data->key->service_id->name);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pop(LuaVM, 1);
        lua_getfield(LuaVM, -1, "version");
        data->key->service_id->version = (unsigned long) lua_tonumber(LuaVM, -1);
      #if VERBOSE
        printf("\t[data->key->service_id->version: %lu]\n", data->key->service_id->version);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pop(LuaVM, 1);

        lua_pushlightuserdata(LuaVM, data->key->service_id);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);

        lua_getfield(LuaVM, -1, "actual_data_id");
        luastring = lua_tolstring(LuaVM, -1, &size);
        data->key->actual_data_id = new char[ size + 1 ];
        memcpy(data->key->actual_data_id, luastring, size);
        data->key->actual_data_id[ size ] = '\0';
      #if VERBOSE
        printf("\t[data->key->actual_data_id: %s]\n", data->key->actual_data_id);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pop(LuaVM, 1);

        lua_pushlightuserdata(LuaVM, data->key);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);

        lua_getfield(LuaVM, -1, "metadata");
        for (int y = 1; ; y++) {
          lua_pushnumber(LuaVM, y);
          lua_gettable(LuaVM, -2);
          if (!lua_istable(LuaVM, -1)) {
//             lua_pop(LuaVM, 1);
            break;
          } else {
            if (y == 1) {
              data->metadata = new MetadataList(256);
            }
            Metadata* metadata = new Metadata;
            lua_getfield(LuaVM, -1, "name");
            const char * luastring = lua_tolstring(LuaVM, -1, &size);
            metadata->name = new char[ size + 1 ];
            memcpy(metadata->name, luastring, size);
            metadata->name[ size ] = '\0';
          #if VERBOSE
            printf("\t[metadata->name: %s]\n", metadata->name);
          #endif
            lua_pop(LuaVM, 1);
            lua_getfield(LuaVM, -1, "value");
            luastring = lua_tolstring(LuaVM, -1, &size);
            metadata->value = new char[ size + 1 ];
            memcpy(metadata->value, luastring, size);
            metadata->value[ size ] = '\0';
          #if VERBOSE
            printf("\t[metadata->value: %s]\n", metadata->value);
          #endif
            lua_pop(LuaVM, 2);
            data->metadata->newmember(metadata);
          }
        }
        lua_pop(LuaVM, 2);

        lua_pushlightuserdata(LuaVM, data);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);
      #if VERBOSE
        printf("\t[DataList[%d] desempilhada]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
        returnValue->newmember(data);
      #if VERBOSE
        printf("\t[DataList[%d] criado...]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
      } /* if */
    } /* for */
  /* retira indice da pilha e valor de retorno*/
    lua_pop(LuaVM, 2);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::getRoots() FIM]\n\n");
  #endif
    return returnValue;
  }

  DataList* IDataService::getChildren(DataKey* key) {
    DataList* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IDataService::getChildren() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getChildren");
  #if VERBOSE
    printf("\t[metodo getChildren empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, key);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro key=%p empilhado]\n", key);
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
      printf("[IDataService::getChildren() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    for (int x = 1;; x++)
    {
      lua_pushnumber(LuaVM, x);
      lua_gettable(LuaVM, -2);
      if (!lua_istable(LuaVM, -1))
      {
        break;
      } else {
        if (x == 1)
        {
      #if VERBOSE
        printf("\t[gerando valor de retorno do tipo DataList]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
          returnValue = new DataList(256);
        } /* if */
        Data* data = new Data;
        data->key = new DataKey;
        data->key->service_id = new scs::core::ComponentId;
      #if VERBOSE
        printf("\t[DataList[%d]] C++: %p\n", x, data);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif

        lua_getfield(LuaVM, -1, "key");
        lua_getfield(LuaVM, -1, "service_id");
        lua_getfield(LuaVM, -1, "name");
        const char * luastring = lua_tolstring(LuaVM, -1, &size);
        data->key->service_id->name = new char[ size + 1 ];
        memcpy(data->key->service_id->name, luastring, size);
        data->key->service_id->name[ size ] = '\0';
      #if VERBOSE
        printf("\t[data->key->service_id->name: %s]\n", data->key->service_id->name);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pop(LuaVM, 1);
        lua_getfield(LuaVM, -1, "version");
        data->key->service_id->version = (unsigned long) lua_tonumber(LuaVM, -1);
      #if VERBOSE
        printf("\t[data->key->service_id->version: %lu]\n", data->key->service_id->version);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pop(LuaVM, 1);

        lua_pushlightuserdata(LuaVM, data->key->service_id);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);

        lua_getfield(LuaVM, -1, "actual_data_id");
        luastring = lua_tolstring(LuaVM, -1, &size);
        data->key->actual_data_id = new char[ size + 1 ];
        memcpy(data->key->actual_data_id, luastring, size);
        data->key->actual_data_id[ size ] = '\0';
      #if VERBOSE
        printf("\t[data->key->actual_data_id: %s]\n", data->key->actual_data_id);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pop(LuaVM, 1);

        lua_pushlightuserdata(LuaVM, data->key);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);

        lua_getfield(LuaVM, -1, "metadata");
        for (int y = 1; ; y++) {
          lua_pushnumber(LuaVM, y);
          lua_gettable(LuaVM, -2);
          if (!lua_istable(LuaVM, -1)) {
//             lua_pop(LuaVM, 1);
            break;
          } else {
            if (y == 1) {
              data->metadata = new MetadataList(256);
            }
            Metadata* metadata = new Metadata;
            lua_getfield(LuaVM, -1, "name");
            const char * luastring = lua_tolstring(LuaVM, -1, &size);
            metadata->name = new char[ size + 1 ];
            memcpy(metadata->name, luastring, size);
            metadata->name[ size ] = '\0';
          #if VERBOSE
            printf("\t[metadata->name: %s]\n", metadata->name);
          #endif
            lua_pop(LuaVM, 1);
            lua_getfield(LuaVM, -1, "value");
            luastring = lua_tolstring(LuaVM, -1, &size);
            metadata->value = new char[ size + 1 ];
            memcpy(metadata->value, luastring, size);
            metadata->value[ size ] = '\0';
          #if VERBOSE
            printf("\t[metadata->value: %s]\n", metadata->value);
          #endif
            lua_pop(LuaVM, 2);
            data->metadata->newmember(metadata);
          }
        }
        lua_pop(LuaVM, 2);

        lua_pushlightuserdata(LuaVM, data);
        lua_insert(LuaVM, -2);
        lua_settable(LuaVM, LUA_REGISTRYINDEX);
      #if VERBOSE
        printf("\t[DataList[%d] desempilhada]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
        returnValue->newmember(data);
      #if VERBOSE
        printf("\t[DataList[%d] criado...]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
      } /* if */
    } /* for */
  /* retira indice da pilha e valor de retorno*/
    lua_pop(LuaVM, 2);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::getChildren() FIM]\n\n");
  #endif
    return returnValue;
  }

  DataKey* IDataService::createDataFrom(DataKey* parent_key, DataKey* source_key) {
    DataKey* returnValue;
    size_t size;
  #if VERBOSE
    printf("[(%p)IDataService::createDataFrom() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "createDataFrom");
  #if VERBOSE
    printf("\t[metodo createDataFrom empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, parent_key);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro parent_key=%p empilhado]\n", parent_key);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_pushlightuserdata(LuaVM, source_key);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro source_key=%p empilhado]\n", source_key);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    if (lua_pcall(LuaVM, 4, 1, 0) != 0) {
      const char* exceptionType = lua_typename(LuaVM, lua_type(LuaVM, -1));
    #if VERBOSE
      printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , exceptionType ) ;
    #endif
      lua_pushvalue(LuaVM, -1);
      const char * errmsg ;
      lua_getglobal( LuaVM, "tostring" ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_pcall( LuaVM, 1, 1, 0 ) ;
      errmsg = lua_tostring( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
      if (strcmp(exceptionType, "table") == 0) {
        const char* repID;
        lua_pushnumber(LuaVM, 1);
        lua_gettable(LuaVM, -2);
        repID = lua_tostring(LuaVM, -1);
        lua_pop(LuaVM, 2) ;
      #if VERBOSE
        printf( "\t[lancando excecao: %s]\n", errmsg ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IDataEntry::copyFrom() FIM]\n\n" ) ;
      #endif
        if (strcmp(repID, "IDL:openbusidl/ds/OperationNotSupported:1.0") == 0) {
          throw new OperationNotSupported;
        } else if (strcmp(repID, "IDL:openbusidl/ds/UnknownType:1.0") == 0) {
          throw new UnknownType;
        } else {
          throw errmsg;
        }
      } else {
      #if VERBOSE
        printf( "\t[lancando excecao: %s]\n", errmsg ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IDataEntry::copyFrom() FIM]\n\n" ) ;
      #endif
        lua_pop(LuaVM, 1);
      }
    } /* if */
    returnValue = new DataKey;
    lua_getfield(LuaVM, -1, "service_id");
    lua_getfield(LuaVM, -1, "name");
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue->service_id->name = new char[ size + 1 ];
    memcpy(returnValue->service_id->name, luastring, size);
    returnValue->service_id->name[ size ] = '\0';
  #if VERBOSE
    printf("\t[key->service_id->name: %s]\n", returnValue->service_id->name);
    printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
  #endif
    lua_pop(LuaVM, 1);
    lua_getfield(LuaVM, -1, "version");
    returnValue->service_id->version = (unsigned long) lua_tonumber(LuaVM, -1);
  #if VERBOSE
    printf("\t[key->service_id->version: %lu]\n", returnValue->service_id->version);
    printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
  #endif
    lua_pop(LuaVM, 1);
    lua_pushlightuserdata(LuaVM, returnValue);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::createDataFrom() FIM]\n\n");
  #endif
    return returnValue;
  }

  DataKey* IDataService::createData(DataKey* parent_key, MetadataList* metadata) {
    DataKey* returnValue;
  #if VERBOSE
    printf("[(%p)IDataService::createData() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "createData");
  #if VERBOSE
    printf("\t[metodo createData empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, parent_key);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro parent_key=%p empilhado]\n", parent_key);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
  #if VERBOSE
    printf("\t[parâmetro metadataList]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_newtable(LuaVM);
    for (int x = 1; x <= metadata->length(); x++) {
      lua_pushnumber(LuaVM, x);
      lua_newtable(LuaVM);
      Metadata* md = metadata->getmember(x-1);
      lua_pushstring(LuaVM, md->name);
      lua_setfield(LuaVM, -2, "name");
      lua_pushstring(LuaVM, md->value);
      lua_setfield(LuaVM, -2, "value");
      lua_settable(LuaVM, -3);
    #if VERBOSE
      printf("\t[metadata[%d]\n", x);
      printf("\t[metadata[%d]->name: %s\n", x, md->name);
      printf("\t[metadata[%d]->value: %s\n", x, md->value);
      printf("\t[Tamanho da pilha de Lua: %d]\n", lua_gettop(LuaVM));
    #endif
    }
    if (lua_pcall(LuaVM, 4, 1, 0) != 0) {
      const char* exceptionType = lua_typename(LuaVM, lua_type(LuaVM, -1));
    #if VERBOSE
      printf( "\t[ERRO ao realizar pcall do metodo]\n" ) ;
      printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
      printf( "\t[Tipo do elemento do TOPO: %s]\n" , exceptionType ) ;
    #endif
      lua_pushvalue(LuaVM, -1);
      const char * errmsg ;
      lua_getglobal( LuaVM, "tostring" ) ;
      lua_insert( LuaVM, -2 ) ;
      lua_pcall( LuaVM, 1, 1, 0 ) ;
      errmsg = lua_tostring( LuaVM, -1 ) ;
      lua_pop( LuaVM, 1 ) ;
      if (strcmp(exceptionType, "table") == 0) {
        const char* repID;
        lua_pushnumber(LuaVM, 1);
        lua_gettable(LuaVM, -2);
        repID = lua_tostring(LuaVM, -1);
        lua_pop(LuaVM, 2) ;
      #if VERBOSE
        printf( "\t[lancando excecao: %s]\n", errmsg ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IDataService::createData() FIM]\n\n" ) ;
      #endif
        if (strcmp(repID, "IDL:openbusidl/ds/OperationNotSupported:1.0") == 0) {
          throw new OperationNotSupported;
        } else if (strcmp(repID, "IDL:openbusidl/ds/UnknownType:1.0") == 0) {
          throw new UnknownType;
        } else {
          throw errmsg;
        }
      } else {
      #if VERBOSE
        printf( "\t[lancando excecao: %s]\n", errmsg ) ;
        printf( "\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop( LuaVM ) ) ;
        printf( "[IDataService::createData() FIM]\n\n" ) ;
      #endif
        lua_pop(LuaVM, 1);
      }
    } /* if */
    returnValue = new DataKey;
    lua_pushlightuserdata(LuaVM, returnValue);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::createData() FIM]\n\n");
  #endif
    return returnValue;
  }

  bool IDataService::deleteData (DataKey* key) {
    bool returnValue;
  #if VERBOSE
    printf("[(%p)IDataService::deleteData() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "deleteData");
  #if VERBOSE
    printf("\t[metodo createDirectory empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, key);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro key=%p empilhado]\n", key);
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
      printf("[IDataService::deleteData() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    returnValue = lua_toboolean(LuaVM, -1);
    lua_pop(LuaVM, 1);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::deleteData() FIM]\n\n");
  #endif
    return returnValue;
  }

  Data* IDataService::getData(DataKey* key) {
    Data* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IDataService::getData() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getData");
  #if VERBOSE
    printf("\t[metodo getData empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);
    lua_pushlightuserdata(LuaVM, key);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[parâmetro key=%p empilhado]\n", key);
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
      printf("[IDataService::getData() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    returnValue = new Data;
    returnValue->key = new DataKey;
    returnValue->key->service_id = new scs::core::ComponentId;

    lua_getfield(LuaVM, -1, "key");
    lua_getfield(LuaVM, -1, "service_id");
    lua_getfield(LuaVM, -1, "name");
    const char * luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue->key->service_id->name = new char[ size + 1 ];
    memcpy(returnValue->key->service_id->name, luastring, size);
    returnValue->key->service_id->name[ size ] = '\0';
  #if VERBOSE
    printf("\t[data->key->service_id->name: %s]\n", returnValue->key->service_id->name);
    printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
  #endif
    lua_pop(LuaVM, 1);
    lua_getfield(LuaVM, -1, "version");
    returnValue->key->service_id->version = (unsigned long) lua_tonumber(LuaVM, -1);
  #if VERBOSE
    printf("\t[data->key->service_id->version: %lu]\n", returnValue->key->service_id->version);
    printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
  #endif
    lua_pop(LuaVM, 1);

    lua_pushlightuserdata(LuaVM, returnValue->key->service_id);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);

    lua_getfield(LuaVM, -1, "actual_data_id");
    luastring = lua_tolstring(LuaVM, -1, &size);
    returnValue->key->actual_data_id = new char[ size + 1 ];
    memcpy(returnValue->key->actual_data_id, luastring, size);
    returnValue->key->actual_data_id[ size ] = '\0';
  #if VERBOSE
    printf("\t[data->key->actual_data_id: %s]\n", returnValue->key->actual_data_id);
    printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
  #endif
    lua_pop(LuaVM, 1);

    lua_pushlightuserdata(LuaVM, returnValue);
    lua_insert(LuaVM, -2);
    lua_settable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::getData() FIM]\n\n");
  #endif
    return returnValue;
  }

  void IDataService::_getDataFacet(void* ptr, DataKey* key, char* facet_interface) {
    IDataEntry* returnValue = NULL;
  #if VERBOSE
    printf("[(%p)IDataService::getDataFacet() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getDataFacet");
  #if VERBOSE
    printf("\t[metodo getDataFacet empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);

    lua_newtable(LuaVM);
    lua_pushstring(LuaVM, key->actual_data_id);
    lua_setfield(LuaVM, -2, "actual_data_id");
    lua_newtable(LuaVM);
    lua_pushstring(LuaVM, key->service_id->name);
    lua_setfield(LuaVM, -2, "name");
    lua_pushnumber(LuaVM, key->service_id->version);
    lua_setfield(LuaVM, -2, "version");
    lua_setfield(LuaVM, -2, "service_id");
  #if VERBOSE
    printf("\t[parâmetro dataKey:]\n\t[dataKey->actual_data_id: %s]\n\t[dataKey->service_id->name: %s]\n\t" \
        "[dataKey->service_id->version: %lu]\n", key->actual_data_id, key->service_id->name, key->service_id->version);
  #endif

    lua_pushstring(LuaVM, facet_interface);
  #if VERBOSE
    printf("\t[parâmetro facet_interface=%s empilhado]\n", facet_interface);
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
      printf("[IDataService::getDataFacet() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
      lua_getglobal(LuaVM, "orb");
      lua_getfield(LuaVM, -1, "narrow");
      lua_getglobal(LuaVM, "orb");
      lua_pushvalue(LuaVM, -4);
      lua_pushstring(LuaVM, facet_interface);
      lua_pcall(LuaVM, 3, 1, 0);
    #if VERBOSE
      const void* luaRef = lua_topointer(LuaVM, -1);
    #endif
      lua_pushlightuserdata(LuaVM, ptr);
      lua_insert(LuaVM, -2);
      lua_settable(LuaVM, LUA_REGISTRYINDEX);
    #if VERBOSE
      printf("\t[OBJ Lua:%p C:%p]\n", luaRef, ptr);
      printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      printf("\t[Tipo do elemento do TOPO: %s]\n" , \
          lua_typename(LuaVM, lua_type(LuaVM, -1)));
    #endif
      lua_pop(LuaVM, 2);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::getDataFacet() FIM]\n\n");
  #endif
  }

  scs::core::NameList* IDataService::getFacetInterfaces(DataKey* key) {
    scs::core::NameList* returnValue = NULL;
    size_t size;
  #if VERBOSE
    printf("[(%p)IDataService::getFacetInterfaces() COMECO]\n", this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getglobal(LuaVM, "invoke");
    lua_pushlightuserdata(LuaVM, this);
    lua_gettable(LuaVM, LUA_REGISTRYINDEX);
  #if VERBOSE
    printf("\t[IDataService Lua:%p C++:%p]\n", \
      lua_topointer(LuaVM, -1), this);
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
  #endif
    lua_getfield(LuaVM, -1, "getFacetInterfaces");
  #if VERBOSE
    printf("\t[metodo getFacetInterfaces empilhado]\n");
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("\t[Tipo do elemento do TOPO: %s]\n" , \
        lua_typename(LuaVM, lua_type(LuaVM, -1)));
  #endif
    lua_insert(LuaVM, -2);

    lua_newtable(LuaVM);
    lua_pushstring(LuaVM, key->actual_data_id);
    lua_setfield(LuaVM, -2, "actual_data_id");
    lua_newtable(LuaVM);
    lua_pushstring(LuaVM, key->service_id->name);
    lua_setfield(LuaVM, -2, "name");
    lua_pushnumber(LuaVM, key->service_id->version);
    lua_setfield(LuaVM, -2, "version");
    lua_setfield(LuaVM, -2, "service_id");
  #if VERBOSE
    printf("\t[parâmetro dataKey:]\n\t[dataKey->actual_data_id: %s]\n\t[dataKey->service_id->name: %s]\n\t" \
        "[dataKey->service_id->version: %lu]\n", key->actual_data_id, key->service_id->name, key->service_id->version);
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
      printf("[IDataService::getFacetInterfaces() FIM]\n\n");
    #endif
      throw returnValue;
    } /* if */
    for (int x = 1;; x++)
    {
      lua_pushnumber(LuaVM, x);
      lua_gettable(LuaVM, -2);
      if (!lua_isstring(LuaVM, -1))
      {
        break;
      } else {
        if (x == 1)
        {
      #if VERBOSE
        printf("\t[gerando valor de retorno do tipo NameList]\n");
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
          returnValue = new scs::core::NameList(256);
        } /* if */
        char* name;
      #if VERBOSE
        printf("\t[NameList[%d]] C++: %p\n", x, name);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif

        const char * luastring = lua_tolstring(LuaVM, -1, &size);
        name = new char[ size + 1 ];
        memcpy(name, luastring, size);
        name[ size ] = '\0';
      #if VERBOSE
        printf("\t[name: %s]\n", name);
        printf("\t[Tamanho da pilha de Lua: %d]\n",lua_gettop(LuaVM));
      #endif
        lua_pop(LuaVM, 1);

      #if VERBOSE
        printf("\t[NameList[%d] desempilhada]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
        returnValue->newmember(name);
      #if VERBOSE
        printf("\t[NameList[%d] criado...]\n", x);
        printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
      #endif
      } /* if */
    } /* for */
  /* retira indice da pilha e valor de retorno*/
    lua_pop(LuaVM, 2);
  #if VERBOSE
    printf("\t[Tamanho da pilha de Lua: %d]\n" , lua_gettop(LuaVM));
    printf("[IDataService::getFacetInterfaces() FIM]\n\n");
  #endif
    return returnValue;
  }

}

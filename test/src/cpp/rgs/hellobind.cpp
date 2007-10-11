/*
** Lua binding: hello
** Generated automatically by tolua 5.1b on Tue Oct  9 15:36:12 2007.
*/

#ifndef __cplusplus
#include "stdlib.h"
#endif
#include "string.h"

#include "tolua.h"

/* Exported function */
TOLUA_API int tolua_hello_open (lua_State* tolua_S);
LUALIB_API int luaopen_hello (lua_State* tolua_S);

#include "hello.hpp"

/* function to release collected object */
#ifdef __cplusplus
#else
static int tolua_collect (lua_State* tolua_S)
{
 void* self = tolua_tousertype(tolua_S,1,0);
 free(self);
 return 0;
}
#endif


/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"hello");
}

/* method: new of class  hello */
static int tolua_hello_hello_new00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isusertable(tolua_S,1,"hello",0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
 {
  hello* tolua_ret = (hello*)  new hello();
 tolua_pushusertype(tolua_S,(void*)tolua_ret,"hello");
 }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'new'.",&tolua_err);
 return 0;
#endif
}

/* method: delete of class  hello */
static int tolua_hello_hello_delete00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isusertype(tolua_S,1,"hello",0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
  hello* self = (hello*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
 if (!self) tolua_error(tolua_S,"invalid 'self' in function 'delete'",NULL);
#endif
 delete self;
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'delete'.",&tolua_err);
 return 0;
#endif
}

/* method: say_hello of class  hello */
static int tolua_hello_hello_say_hello00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isusertype(tolua_S,1,"hello",0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
  hello* self = (hello*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
 if (!self) tolua_error(tolua_S,"invalid 'self' in function 'say_hello'",NULL);
#endif
 {
  self->say_hello();
 }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'say_hello'.",&tolua_err);
 return 0;
#endif
}

/* Open lib function */
LUALIB_API int luaopen_hello (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
#ifdef __cplusplus
 tolua_cclass(tolua_S,"hello","hello","",0);
#else
 tolua_cclass(tolua_S,"hello","hello","",tolua_collect);
#endif
 tolua_beginmodule(tolua_S,"hello");
 tolua_function(tolua_S,"new",tolua_hello_hello_new00);
 tolua_function(tolua_S,"delete",tolua_hello_hello_delete00);
 tolua_function(tolua_S,"say_hello",tolua_hello_hello_say_hello00);
 tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}
/* Open tolua function */
TOLUA_API int tolua_hello_open (lua_State* tolua_S)
{
 lua_pushcfunction(tolua_S, luaopen_hello);
 lua_pushstring(tolua_S, "hello");
 lua_call(tolua_S, 1, 0);
 return 1;
}

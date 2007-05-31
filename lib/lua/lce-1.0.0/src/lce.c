#include <openssl/err.h>

#include <lce_x509.h>
#include <lce_key.h>
#include <lce_cipher.h>

#include <stdio.h>

#define LCE_TABLENAME "lce"

static const struct luaL_reg lce_x509[] = {
  {"readfromderfile", lce_x509_readfromderfile},
  {NULL, NULL}
};

static const struct luaL_reg lce_x509_methods[] = {
  {"getpublickey", lce_x509_getpublickey},
  {"release", lce_x509_release},
  {NULL, NULL}
};

static const struct luaL_reg lce_key[] = {
  {"readprivatefrompemfile", lce_key_readprivatefrompemfile},
  {NULL, NULL}
};

static const struct luaL_reg lce_cipher[] = {
  {"encrypt", lce_cipher_encrypt},
  {"decrypt", lce_cipher_decrypt},
  {NULL, NULL}
};

static const struct luaL_reg lce_top[] = {
  {NULL, NULL}
};

void lce_createmeta(lua_State *L, const char *tname, const struct luaL_reg methods[]) {
  luaL_newmetatable(L, tname);
  luaL_register(L, NULL, methods);
  lua_pushstring(L, "__index");
  lua_pushvalue(L, -2);
  lua_settable(L, -3);
}

void lce_createmetaUD(lua_State *L, const char *tname, lua_CFunction func_gc) {
  luaL_newmetatable(L, tname);
  lua_pushstring(L, "__gc");
  lua_pushcfunction(L, func_gc);
  lua_settable(L, -3);
}

int luaopen_lce(lua_State *L) {
  ERR_load_crypto_strings();

  lce_createmetaUD(L, META_KEYUD, lce_key_release);

  lce_createmeta(L, META_X509, lce_x509_methods);

  luaL_register(L, LCE_TABLENAME, lce_top);

  lua_pushstring(L, X509_MODULE);
  lua_newtable(L);
  luaL_register(L, NULL, lce_x509);
  lua_settable(L, -3);

  lua_pushstring(L, KEY_MODULE);
  lua_newtable(L);
  luaL_register(L, NULL, lce_key);
  lua_settable(L, -3);

  lua_pushstring(L, CIPHER_MODULE);
  lua_newtable(L);
  luaL_register(L, NULL, lce_cipher);
  lua_settable(L, -3);

  return 1;
}

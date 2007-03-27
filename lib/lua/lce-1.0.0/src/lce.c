#include <openssl/err.h>

#include <lce_x509.h>
#include <lce_key.h>
#include <lce_cipher.h>

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

static const struct luaL_reg lce_key_methods[] = {
  {"release", lce_key_release},
  {NULL, NULL}
};

static const struct luaL_reg lce_cipher[] = {
  {"encrypt", lce_cipher_encrypt},
  {"decrypt", lce_cipher_decrypt},
  {NULL, NULL}
};

void lce_createmeta(lua_State *L, const char *tname, const struct luaL_reg methods[]) {
  luaL_newmetatable(L, tname);
  luaL_register(L, NULL, methods);
  lua_pushstring(L, "__index");
  lua_pushvalue(L, -2);
  lua_settable(L, -3);
}

int luaopen_lce(lua_State *L) {
  ERR_load_crypto_strings();

  lce_createmeta(L, META_KEY, lce_key_methods);
  lce_createmeta(L, META_X509, lce_x509_methods);

  luaL_register(L, X509_MODULE, lce_x509);
  luaL_register(L, KEY_MODULE, lce_key);
  luaL_register(L, CIPHER_MODULE, lce_cipher);

  return 1;
}

#include <lce_x509.h>

#include <errno.h>
#include <string.h>

#include <openssl/x509.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#include <lce_key.h>

static const char * readDERCertificate(const char *filePath, X509 **x509);
static const char * getPublicKey(X509 * x509, EVP_PKEY **publicKey);

int lce_x509_readfromderfile(lua_State *L) {
  const char *filePath;
  X509 *x509;
  const char *errorMessage;

  filePath = luaL_checkstring(L, -1);
  luaL_argcheck(L, filePath != NULL, 1, "file name expected");

  errorMessage = readDERCertificate(filePath, &x509);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  lua_newtable(L);
  lua_pushstring(L, X509_FIELD);
  lua_pushlightuserdata(L, x509);
  lua_settable(L, -3);

  luaL_getmetatable(L, META_X509);
  lua_setmetatable(L, -2);

  return 1;
}

int lce_x509_release(lua_State *L) {
  X509 *x509;

  luaL_argcheck(L, lua_istable(L, -1) == 1, 1, "certificate expected");
  lua_pushstring(L, X509_FIELD);
  lua_gettable(L, -2);

  x509 = (X509 *)lua_touserdata(L, -1);
  luaL_argcheck(L, x509 != NULL, 1, "certificate expected");

  X509_free(x509);

  return 0;
}

int lce_x509_getpublickey(lua_State *L) {
  X509 *x509;
  EVP_PKEY *publicKey;
  const char *errorMessage;

  luaL_argcheck(L, lua_istable(L, -1) == 1, 1, "certificate expected");
  lua_pushstring(L, X509_FIELD);
  lua_gettable(L, -2);

  x509 = (X509 *)lua_touserdata(L, -1);
  luaL_argcheck(L, x509 != NULL, 1, "certificate expected");

  errorMessage = getPublicKey(x509, &publicKey);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  lua_newtable(L);
  lua_pushstring(L, KEY_FIELD);
  lua_pushlightuserdata(L, publicKey);
  lua_settable(L, -3);

  lua_pushstring(L, KEY_TYPE_FIELD);
  lua_pushstring(L, "public");
  lua_settable(L, -3);

  lua_pushstring(L, KEY_ALGORITHM_FIELD);
  lua_pushstring(L, getKeyAlgorithm(publicKey));
  lua_settable(L, -3);

  luaL_getmetatable(L, META_KEY);
  lua_setmetatable(L, -2);

  return 1;
}

static const char * readDERCertificate(const char *filePath, X509 **x509) {
  FILE *certificateFile;

  certificateFile = fopen(filePath, "rb");
  if (certificateFile == NULL) {
    return strerror(errno);
  }

  *x509 = d2i_X509_fp(certificateFile, NULL);
  fclose(certificateFile);

  if (*x509 == NULL ) {
    return ERR_error_string(ERR_get_error(), NULL);
  }

  return NULL;
}

static const char * getPublicKey(X509 * x509, EVP_PKEY **publicKey) {
  *publicKey = X509_get_pubkey(x509);
  if (*publicKey == NULL) {
    return ERR_error_string(ERR_get_error(), NULL);
  }

  return NULL;
}

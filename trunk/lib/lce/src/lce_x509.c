#include <lce_x509.h>

#include <errno.h>
#include <string.h>
#include <stdio.h>

#include <openssl/x509.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#include <lce_key.h>

static const char * readDERCertificateFile(const char *filePath, X509 **x509);
static const char * readDERCertificateMemory(void *data, int dataLength,
    X509 **x509);
static int pushX509(lua_State *L, X509 *x509);
static const char * getPublicKey(X509 * x509, EVP_PKEY **publicKey);

int lce_x509_readfromderfile(lua_State *L) {
  const char *filePath;
  X509 *x509;
  const char *errorMessage;

  filePath = luaL_checkstring(L, -1);
  luaL_argcheck(L, filePath != NULL, 1, "file name expected");

  errorMessage = readDERCertificateFile(filePath, &x509);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  return pushX509(L, x509);
}

int lce_x509_readfromderstring(lua_State *L) {
  const char *data;
  size_t dataLength;
  X509 *x509;
  const char *errorMessage;

  data = luaL_checklstring(L, 1, &dataLength);
  luaL_argcheck(L, data != NULL, 1, "data expected");

  errorMessage = readDERCertificateMemory((void *) data, dataLength, &x509);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  return pushX509(L, x509);
}

static int pushX509(lua_State *L, X509 *x509) {
  X509 **x509UD;

  lua_newtable(L);
  lua_pushstring(L, X509_FIELD);

  x509UD = (X509 **)lua_newuserdata(L, sizeof(X509 **));
  *x509UD = x509;
  luaL_getmetatable(L, META_X509UD);
  lua_setmetatable(L, -2);

  lua_settable(L, -3);

  luaL_getmetatable(L, META_X509);
  lua_setmetatable(L, -2);

  return 1;
}

int lce_x509_release(lua_State *L) {
  X509 *x509;

  x509 = *((X509 **)lua_touserdata(L, -1));
  if (x509)
    X509_free(x509);
  return 0;
}

int lce_x509_getpublickey(lua_State *L) {
  X509 *x509;
  EVP_PKEY *publicKey;
  EVP_PKEY **publicKeyUD;
  const char *errorMessage;

  luaL_argcheck(L, lua_istable(L, -1) == 1, 1, "certificate expected");
  lua_pushstring(L, X509_FIELD);
  lua_gettable(L, -2);

  x509 = *((X509 **)lua_touserdata(L, -1));
  luaL_argcheck(L, x509 != NULL, 1, "certificate expected");

  errorMessage = getPublicKey(x509, &publicKey);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  lua_newtable(L);
  lua_pushstring(L, KEY_FIELD);

  publicKeyUD = (EVP_PKEY **)lua_newuserdata(L, sizeof(EVP_PKEY **));
  *publicKeyUD = publicKey;
  luaL_getmetatable(L, META_KEYUD);
  lua_setmetatable(L, -2);

  lua_settable(L, -3);

  lua_pushstring(L, KEY_TYPE_FIELD);
  lua_pushstring(L, "public");
  lua_settable(L, -3);

  lua_pushstring(L, KEY_ALGORITHM_FIELD);
  lua_pushstring(L, getKeyAlgorithm(publicKey));
  lua_settable(L, -3);

  return 1;
}

static const char * readDERCertificateFile(const char *filePath, X509 **x509) {
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

static const char * readDERCertificateMemory(void *data, int dataLength,
    X509 **x509) {
  BIO *certificateMemory;

  certificateMemory = BIO_new_mem_buf(data, dataLength);
  if (certificateMemory == NULL) {
    return strerror(errno);
  }

  *x509 = d2i_X509_bio(certificateMemory, NULL);
  BIO_free(certificateMemory);

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

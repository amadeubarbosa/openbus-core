#include <lce_key.h>

#include <errno.h>
#include <string.h>
#include <stdio.h>

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/err.h>

static const char * readPEMPrivateKeyFile(const char *filePath, EVP_PKEY **privateKey);
static const char * readPEMPrivateKeyMemory(void *data, int dataLength,
    EVP_PKEY **privateKey);
static int pushKey(lua_State* L, EVP_PKEY *privateKey);

int lce_key_release(lua_State* L) {
  EVP_PKEY *key;

  key = *((EVP_PKEY **)lua_touserdata(L, -1));
  if (key)
    EVP_PKEY_free(key);
  return 0;
}

int lce_key_readprivatefrompemfile(lua_State* L) {
  const char *filePath;
  EVP_PKEY *privateKey;
  const char *errorMessage;

  filePath = luaL_checkstring(L, 1);
  luaL_argcheck(L, filePath != NULL, 1, "file name expected");

  errorMessage = readPEMPrivateKeyFile(filePath, &privateKey);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  return pushKey(L, privateKey);
}

int lce_key_readprivatefrompemstring(lua_State* L) {
  const char *data;
  size_t dataLength;
  EVP_PKEY *privateKey;
  const char *errorMessage;

  data = luaL_checklstring(L, 1, &dataLength);
  luaL_argcheck(L, data != NULL, 1, "data expected");

  errorMessage = readPEMPrivateKeyMemory((void *) data, dataLength, &privateKey);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  return pushKey(L, privateKey);
}

static int pushKey(lua_State* L, EVP_PKEY *privateKey) {
  EVP_PKEY **privateKeyUD;

  lua_newtable(L);
  lua_pushstring(L, KEY_FIELD);

  privateKeyUD = (EVP_PKEY **)lua_newuserdata(L, sizeof(EVP_PKEY **));
  *privateKeyUD = privateKey;
  luaL_getmetatable(L, META_KEYUD);
  lua_setmetatable(L, -2);

  lua_settable(L, -3);

  lua_pushstring(L, KEY_TYPE_FIELD);
  lua_pushstring(L, "private");
  lua_settable(L, -3);

  lua_pushstring(L, KEY_ALGORITHM_FIELD);
  lua_pushstring(L, getKeyAlgorithm(privateKey));
  lua_settable(L, -3);

  return 1;
}

const char * getKeyAlgorithm(EVP_PKEY *key) {
  int keyAlgorithm;
  keyAlgorithm = EVP_PKEY_type(key->type);
  switch (keyAlgorithm) {
    case EVP_PKEY_RSA:
      return "rsa";
    case EVP_PKEY_DSA:
      return "dsa";
    default:
      return "unknown";
  }
}

static const char * readPEMPrivateKeyFile(const char *filePath, EVP_PKEY **privateKey) {
  FILE *privateKeyFile;

  privateKeyFile = fopen(filePath, "r");
  if (privateKeyFile == NULL) {
    return strerror(errno);
  }

  *privateKey = PEM_read_PrivateKey(privateKeyFile, NULL, NULL, NULL);
  fclose(privateKeyFile);

  if (*privateKey == NULL) {
    return ERR_error_string(ERR_get_error(), NULL);
  }

  return NULL;
}

static const char * readPEMPrivateKeyMemory(void *data, int dataLength,
      EVP_PKEY **privateKey) {
  BIO *privateKeyMemory;

  privateKeyMemory = BIO_new_mem_buf(data, dataLength);
  if (privateKeyMemory == NULL) {
    return strerror(errno);
  }

  *privateKey = PEM_read_bio_PrivateKey(privateKeyMemory, NULL, NULL, NULL);
  BIO_free(privateKeyMemory);

  if (*privateKey == NULL) {
    return ERR_error_string(ERR_get_error(), NULL);
  }

  return NULL;
}

#include <lce_cipher.h>

#include <errno.h>
#include <string.h>

#include <lauxlib.h>

#include <openssl/evp.h>
#include <openssl/err.h>

#include <lce_key.h>

static const char * encrypt(EVP_PKEY *publicKey, const char *plainText,
    size_t plainTextSize, char **cryptedTextOut, size_t *cryptedTextSizeOut);

static const char * decrypt(EVP_PKEY *privateKey, const char *cryptedText,
    size_t cryptedTextSize, char **decryptedTextOut, size_t *decryptedTextSizeOut);

int lce_cipher_encrypt(lua_State *L) {
  EVP_PKEY *publicKey;
  const char *plainText;
  size_t plainTextSize;
  char *cryptedText;
  size_t cryptedTextSize;
  const char *errorMessage;

  luaL_argcheck(L, lua_istable(L, 1) == 1, 1, "key expected 1");
  lua_pushstring(L, KEY_FIELD);
  lua_gettable(L, 1);

  publicKey = (EVP_PKEY *)lua_touserdata(L, -1);
  luaL_argcheck(L, publicKey != NULL, 1, "key expected 2");

  plainText = luaL_checklstring(L, 2, &plainTextSize);
  luaL_argcheck(L, plainText != NULL, 2, "data to encrypt expected");

  errorMessage = encrypt(publicKey, plainText, plainTextSize, &cryptedText, &cryptedTextSize);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  lua_pushlstring(L, cryptedText, cryptedTextSize);
  return 1;
}

int lce_cipher_decrypt(lua_State *L) {
  EVP_PKEY *privateKey;
  const char *cryptedText;
  size_t cryptedTextSize;
  char *decryptedText;
  size_t decryptedTextSize;
  const char *errorMessage;

  luaL_argcheck(L, lua_istable(L, 1) == 1, 1, "key expected");
  lua_pushstring(L, KEY_FIELD);
  lua_gettable(L, 1);

  privateKey = (EVP_PKEY *)lua_touserdata(L, -1);
  luaL_argcheck(L, privateKey != NULL, 1, "key expected");

  cryptedText = luaL_checklstring(L, 2, &cryptedTextSize);
  luaL_argcheck(L, cryptedText != NULL, 2, "data to decrypt expected");

  errorMessage = decrypt(privateKey, cryptedText, cryptedTextSize, &decryptedText, &decryptedTextSize);
  if (errorMessage != NULL) {
    lua_pushnil(L);
    lua_pushstring(L, errorMessage);
    return 2;
  }

  lua_pushlstring(L, decryptedText, decryptedTextSize);
  return 1;
}

static const char * encrypt(EVP_PKEY *publicKey, const char *plainText,
    size_t plainTextSize, char **cryptedTextOut, size_t *cryptedTextSizeOut) {
  EVP_PKEY_CTX *context;
  size_t cryptedTextSize;
  char *cryptedText;

  context = EVP_PKEY_CTX_new(publicKey, NULL);
  if (!context) {
    return ERR_error_string(ERR_get_error(), NULL);
  }

  if (EVP_PKEY_encrypt_init(context) <= 0) {
    EVP_PKEY_CTX_free(context);
    return ERR_error_string(ERR_get_error(), NULL);
  }

  if (EVP_PKEY_encrypt(context, NULL, &cryptedTextSize, plainText, plainTextSize) <= 0) {
    EVP_PKEY_CTX_free(context);
    return ERR_error_string(ERR_get_error(), NULL);
  }

  cryptedText = malloc(cryptedTextSize);
  if (cryptedText == NULL) {
    char *errorMessage = strerror(errno);
    EVP_PKEY_CTX_free(context);
    return errorMessage;
  }

  if (EVP_PKEY_encrypt(context, cryptedText, &cryptedTextSize, plainText, plainTextSize) <= 0) {
    free(cryptedText);
    EVP_PKEY_CTX_free(context);
    return ERR_error_string(ERR_get_error(), NULL);
  }

  *cryptedTextOut = cryptedText;
  *cryptedTextSizeOut = cryptedTextSize;

  EVP_PKEY_CTX_free(context);

  return NULL;
}

static const char * decrypt(EVP_PKEY *privateKey, const char *cryptedText,
    size_t cryptedTextSize, char **decryptedTextOut, size_t *decryptedTextSizeOut) {
  EVP_PKEY_CTX *context;
  size_t decryptedTextSize;
  char *decryptedText;

  context = EVP_PKEY_CTX_new(privateKey, NULL);
  if (!context) {
    return ERR_error_string(ERR_get_error(), NULL);
  }

  if (EVP_PKEY_decrypt_init(context) <= 0) {
    EVP_PKEY_CTX_free(context);
    return ERR_error_string(ERR_get_error(), NULL);
  }

  if (EVP_PKEY_decrypt(context, NULL, &decryptedTextSize, cryptedText, cryptedTextSize) <= 0) {
    EVP_PKEY_CTX_free(context);
    return ERR_error_string(ERR_get_error(), NULL);
  }

  decryptedText = malloc(decryptedTextSize);
  if (decryptedText == NULL) {
    char *errorMessage = strerror(errno);
    EVP_PKEY_CTX_free(context);
    return errorMessage;
  }

  if (EVP_PKEY_decrypt(context, decryptedText, &decryptedTextSize, cryptedText, cryptedTextSize) <= 0) {
    free(decryptedText);
    EVP_PKEY_CTX_free(context);
    return ERR_error_string(ERR_get_error(), NULL);
  }

  *decryptedTextOut = decryptedText;
  *decryptedTextSizeOut = decryptedTextSize;

  EVP_PKEY_CTX_free(context);

  return NULL;
}

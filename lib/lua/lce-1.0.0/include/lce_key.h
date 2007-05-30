#ifndef __LCE_KEY_H__
#define __LCE_KEY_H__

#include <lauxlib.h>

#include <openssl/evp.h>

#define KEY_MODULE "key"

#define META_KEY "LCE_key"

#define KEY_FIELD "__key"
#define KEY_TYPE_FIELD "type"
#define KEY_ALGORITHM_FIELD "algorithm"

int lce_key_release(lua_State *L);
int lce_key_readprivatefrompemfile(lua_State *L);

const char * getKeyAlgorithm(EVP_PKEY *key);

#endif

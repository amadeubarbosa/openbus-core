#ifndef __LCE_CIPHER_H__
#define __LCE_CIPHER_H__

#include <lauxlib.h>

#define CIPHER_MODULE "lce.cipher"

int lce_cipher_encrypt(lua_State *L);
int lce_cipher_decrypt(lua_State *L);

#endif

#ifndef __LCE_X509_H__
#define __LCE_X509_H__

#include <lauxlib.h>

#define X509_MODULE "lce.x509"

#define META_X509 "LCE.x509"

#define X509_FIELD "__x509"

int lce_x509_readfromderfile(lua_State *L);
int lce_x509_getpublickey(lua_State *L);
int lce_x509_release(lua_State *L);

#endif

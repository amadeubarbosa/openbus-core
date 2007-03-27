PROJNAME = lce
LIBNAME = lce-1.0.0

SRC = lce.c lce_x509.c lce_key.c lce_cipher.c

INCLUDES = ../include /local/prod/rodrigoh/software/openssl-SNAP-20070314/include ${LUA_HOME}/include

LDIR = /local/prod/rodrigoh/software/openssl-SNAP-20070314

LIBS = crypto dl

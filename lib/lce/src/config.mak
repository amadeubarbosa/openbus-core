PROJNAME = lce
LIBNAME = ${PROJNAME}

INCLUDES= ../include
LIBS= dl crypto
SRC= lce.c lce_x509.c lce_key.c lce_cipher.c

USE_LUA51=YES

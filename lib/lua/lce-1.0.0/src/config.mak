PROJNAME = lce
LIBNAME = ${PROJNAME}

TARGETROOT= ${OPENBUS_HOME}/libpath

OPENSSL_HOME= /home/msv/rodrigoh/public/openssl
OPENSSL_INC= ${OPENSSL_HOME}/include
OPENSSL_LIB= ${OPENSSL_HOME}
OPENSSL_LIBS = crypto dl

INCLUDES= ../include ${OPENSSL_INC}
LDIR= ${OPENSSL_LIB}
LIBS= ${OPENSSL_LIBS}
SRC= lce.c lce_x509.c lce_key.c lce_cipher.c

USE_LUA51=YES
USE_STATIC=YES

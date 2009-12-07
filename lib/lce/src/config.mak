PROJNAME = lce
LIBNAME = ${PROJNAME}

OPENBUSINC = ${OPENBUS_HOME}/incpath
OPENBUSLIB = ${OPENBUS_HOME}/libpath/${TEC_UNAME}

LDIR= ${OPENBUSLIB}

INCLUDES= ../include ${OPENBUSINC}/openssl-0.9.9
LIBS= dl crypto
SRC= lce.c lce_x509.c lce_key.c lce_cipher.c

USE_LUA51=YES
NO_LUALINK=YES

#file "config.mak"

PROJNAME = lualdap
LIBNAME = ${PROJNAME}

TARGETROOT= ${OPENBUS_HOME}/libpath

# OpenLDAP includes directory
OPENLDAP_INC= /usr/local/include
# OpenLDAP library (an optional directory can be specified with -L<dir>)
OPENLDAP_LIB= ldap

INCLUDES= $(OPENLDAP_INC)
LIBS= $(OPENLDAP_LIB)
SRC=  lualdap.c

USE_LUA51=YES
USE_STATIC=YES

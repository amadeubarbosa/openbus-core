EXTRA_CONFIG= ${OPENBUS_HOME}/config

PROJNAME = lualdap
LIBNAME = ${PROJNAME}

TARGETROOT= ${OPENBUS_HOME}/libpath

# OpenLDAP library (an optional directory can be specified with -L<dir>)
OPENLDAP_LIB= ldap

INCLUDES= $(OPENLDAP_INC)
LIBS= $(OPENLDAP_LIB)
SRC=  lualdap.c

USE_LUA51=YES
USE_STATIC=YES

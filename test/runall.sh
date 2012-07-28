#!/bin/bash

CONSOLE="${OPENBUS_HOME}/bin/busconsole"

if [ "$1" == "DEBUG" ]; then
	CONSOLE="$CONSOLE -d"
elif [ "$1" != "RELEASE" ]; then
	echo "Usage: runall.sh [RELEASE|DEBUG]"
	exit 1
fi

RUNNER="${CONSOLE} ${OPENBUS_HOME}/lib/lua/5.1/latt/ConsoleTestRunner.lua"

LUACASES="\
openbus/test/core/services/LoginDB \
openbus/test/core/Protocol \
"
for case in ${LUACASES}; do
	echo -n "Test '${case}' ... "
	${CONSOLE} ${case}.lua || exit $?
	echo "OK"
done

LATTCASES="\
openbus/test/core/services/LoginRegistry \
openbus/test/core/services/CertificateRegistry \
openbus/test/core/services/EntityRegistry \
openbus/test/core/services/OfferRegistry \
openbus/test/core/admin/admin \
"
#openbus/test/core/services/LDAPAuthentication
for case in ${LATTCASES}; do
	echo "LATT '${case}':"
	${RUNNER} ${case}.lua ${@:2:${#@}} || exit $?
done

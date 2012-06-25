#!/bin/sh

CONSOLE="${OPENBUS_HOME}/bin/busconsole"
RUNNER="${CONSOLE} ${OPENBUS_HOME}/lib/lua/5.1/latt/ConsoleTestRunner.lua"
TESTDIR=${OPENBUS_HOME}/test/openbus/test/core

LUACASES="\
services/LoginDB \
Protocol \
"
for case in ${LUACASES}; do
	echo -n "Test '${case}' ... "
	${CONSOLE} ${TESTDIR}/${case}.lua
	echo "OK"
done

LATTCASES="\
services/LoginRegistry \
services/CertificateRegistry \
services/EntityRegistry \
services/OfferRegistry \
admin/admin \
"
#LDAPAuthentication
for case in ${LATTCASES}; do
	echo "LATT '${case}':"
	${RUNNER} ${TESTDIR}/${case}.lua
done

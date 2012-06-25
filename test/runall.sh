#!/bin/bash

CONSOLE="${OPENBUS_HOME}/bin/busconsole"
RUNNER="${CONSOLE} ${OPENBUS_HOME}/lib/lua/5.1/latt/ConsoleTestRunner.lua"
TESTDIR=${OPENBUS_HOME}/test

LUACASES="\
openbus/test/core/services/LoginDB \
openbus/test/core/Protocol \
"
for case in ${LUACASES}; do
	echo -n "Test '${case}' ... "
	${CONSOLE} ${TESTDIR}/${case}.lua $@ || exit $?
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
	${RUNNER} ${TESTDIR}/${case}.lua || exit $?
done

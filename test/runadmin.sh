#!/bin/bash

mode=$1
bushost=$2
busport=$3

busadmin="env LUA_PATH=${OPENBUS_CORESDKLUA_TEST}/?.lua ${OPENBUS_CORE_HOME}/bin/busadmin"

if [[ "$mode" == "DEBUG" ]]; then
	busadmin="$busadmin DEBUG"
elif [[ "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG> <bus host> <bus port> <args>"
	exit 1
fi

runconsole="env \
OPENBUS_SDKLUA_HOME=${OPENBUS_CORESDKLUA_HOME} \
OPENBUS_SDKLUA_TEST=${OPENBUS_CORESDKLUA_TEST} \
/bin/bash ${OPENBUS_CORESDKLUA_TEST}/runconsole.sh $mode"

admin=`$runconsole -l openbus.test.configs -e 'print(admin)'`
admpsw=`$runconsole -l openbus.test.configs -e 'print(admpsw)'`

$busadmin \
	--host=$bushost \
	--port=$busport \
	--login=$admin \
	--password=$admpsw \
	${@:4:${#@}} \
	|| exit $?

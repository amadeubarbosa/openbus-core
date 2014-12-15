#!/bin/bash

mode=$1
bushost=$2
busport=$3

busadmin="${OPENBUS_CORE_HOME}/bin/busadmin"
busconsole="${OPENBUS_SDKLUA_HOME}/bin/busconsole"

if [[ "$mode" == "DEBUG" ]]; then
	busadmin="$busadmin DEBUG"
	busconsole="$busconsole DEBUG"
elif [[ "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG> <bus host> <bus port> <args>"
	exit 1
fi

admin=`$busconsole -lopenbus.test.configs -e'print(admin)'`
admpsw=`$busconsole -lopenbus.test.configs -e'print(admpsw)'`

$busadmin \
	--host=$bushost \
	--port=$busport \
	--login=$admin \
	--password=$admpsw \
	${@:4:${#@}} \
	|| exit $?

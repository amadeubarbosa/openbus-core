#!/bin/bash

mode=$1
bushost=$2
busport=$3
param=${4%%=*}
desc=${4#--*=}

busadmin="env LUA_PATH=${OPENBUS_SDKLUA_TEST}/?.lua ${OPENBUS_CORE_HOME}/bin/busadmin"
busadmdesc="${OPENBUS_CORE_HOME}/bin/busadmdesc.lua"

if [[ "$mode" == "DEBUG" ]]; then
	busadmin="$busadmin DEBUG"
elif [[ "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG> <bus host> <bus port> <args>"
	exit 1
fi

op=
if [[ "$param" == "--undo-script" ]]; then
	op=-unload
elif [[ "$param" != "--script" ]]; then
	echo "Only valid arguments are '--script=<path>' or '--undo-script=<path>'"
	exit 1
fi

admin=`$busadmin -l openbus.test.configs -e 'print(admin)'`
admpsw=`$busadmin -l openbus.test.configs -e 'print(admpsw)'`
domain=`$busadmin -l openbus.test.configs -e 'print(domain)'`

$busadmin \
	-busref "$bushost:$busport" \
	-entity $admin \
	-password $admpsw \
	-domain $domain \
	$busadmdesc \
		$op $desc \
	|| exit $?

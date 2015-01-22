#!/bin/bash

mode=$1
bushost=$2
busport=$3
param=${4%%=*}
desc=${4#--*=}

busadmin="${OPENBUS_CORE_HOME}/bin/busadmin"
busdescriptor="${OPENBUS_CORE_HOME}/bin/busdescriptor.lua"
busconsole="${OPENBUS_SDKLUA_HOME}/bin/busconsole"

if [[ "$mode" == "DEBUG" ]]; then
	busadmin="$busadmin DEBUG"
	busconsole="$busconsole DEBUG"
elif [[ "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG> <bus host> <bus port> <args>"
	exit 1
fi

op=
if [[ "$param" == "--undo-script" ]]; then
	op=-u
elif [[ "$param" != "--script" ]]; then
	echo "Only valid arguments are '--script=<path>' or '--undo-script=<path>'"
	exit 1
fi

admin=`$busconsole -l openbus.test.configs -e 'print(admin)'`
admpsw=`$busconsole -l openbus.test.configs -e 'print(admpsw)'`
domain=`$busconsole -l openbus.test.configs -e 'print(domain)'`

$busadmin \
	-host $bushost \
	-port $busport \
$busdescriptor \
	-entity $admin \
	-password $admpsw \
	-domain $domain \
	$op $desc \
	|| exit $?

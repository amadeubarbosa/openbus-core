#!/bin/bash

mode=$1
name=$2
port=$3

buscore="${OPENBUS_CORE_HOME}/bin/busservices"
busconsole="${OPENBUS_SDKLUA_HOME}/bin/busconsole"
busssl="${OPENBUS_OPENSSL_HOME}/bin/openssl"

if [[ "$mode" == "DEBUG" ]]; then
	buscore="$buscore DEBUG"
	busconsole="$busconsole DEBUG"
elif [[ "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG> <port> <name>"
	exit 1
fi

function genkey {
	if [[ ! -e $1.key ]]; then
		export DYLD_LIBRARY_PATH="${OPENBUS_OPENSSL_HOME}/lib:${DYLD_LIBRARY_PATH}"
		$busssl genrsa -out $1.tmp 2048 > /dev/null 2> /dev/null
		$busssl pkcs8 -topk8 -nocrypt -in $1.tmp \
		  -out $1.key -outform DER
		rm -f $1.tmp > /dev/null 2> /dev/null
		echo "BR
Rio de Janeiro
Rio de Janeiro
PUC-Rio
Tecgraf
${1:0:64}
openbus@tecgraf.puc-rio.br
" | $busssl req -config ${OPENBUS_OPENSSL_HOME}/openssl/openssl.cnf -new -x509 \
		  -key $1.key -keyform DER \
		  -out $1.crt -outform DER > /dev/null 2> /dev/null
	fi
}

admin=`$busconsole -lopenbus.test.configs -e'print(admin)'`
admpsw=`$busconsole -lopenbus.test.configs -e'print(admpsw)'`
domain=`$busconsole -lopenbus.test.configs -e'print(domain)'`
leasetime=`$busconsole -lopenbus.test.configs -e'print(leasetime)'`
expirationgap=`$busconsole -lopenbus.test.configs -e'print(expirationgap)'`
passwordpenalty=`$busconsole -lopenbus.test.configs -e'print(passwordpenalty)'`

genkey $OPENBUS_TEMP/$name

$buscore \
	-port=$port \
	-iorfile=$OPENBUS_TEMP/$name.ior \
	-database=$OPENBUS_TEMP/$name.db \
	-privatekey=$OPENBUS_TEMP/$name.key \
	-certificate=$OPENBUS_TEMP/$name.crt \
	-validator $domain:openbus.test.core.services.TesterUserValidator \
	-tokenvalidator $domain:openbus.test.core.services.TestTokenValidator \
	-legacydomain $domain \
	-admin $admin \
	-badpasswordpenalty $passwordpenalty \
	-leasetime $leasetime \
	-expirationgap $expirationgap \
	-loglevel 5 \
	-logfile $OPENBUS_TEMP/$name.log > $OPENBUS_TEMP/$name.out 2>&1 &
	pid="$pid $!"
	trap "kill $pid > /dev/null 2>&1" 0

$busconsole -e"
	local socket = require 'socket.core'
	for _=1, 10 do
		if assert(socket.tcp()):connect('localhost', $port) then
			break
		end
		socket.sleep(1)
	end
"

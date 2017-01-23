#!/bin/bash

mode=$1
name=$2
port=$3

busssl="env LD_LIBRARY_PATH=$OPENBUS_OPENSSL_HOME/lib DYLD_LIBRARY_PATH=$OPENBUS_OPENSSL_HOME/lib ${OPENBUS_OPENSSL_HOME}/bin/openssl"
buscore="env LUA_PATH=${OPENBUS_CORE_TEST}/?.lua;${OPENBUS_CORESDKLUA_TEST}/?.lua ${OPENBUS_CORE_HOME}/bin/busservices"
busadmin="env LUA_PATH=${OPENBUS_CORESDKLUA_TEST}/?.lua ${OPENBUS_CORE_HOME}/bin/busadmin"

if [[ "$mode" == "DEBUG" ]]; then
	buscore="$buscore DEBUG"
elif [[ "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG> <port> <name>"
	exit 1
fi

function genkey {
	if [[ ! -e $1.key ]]; then
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

admin=`$busadmin -l openbus.test.configs -e 'print(admin)'`
admpsw=`$busadmin -l openbus.test.configs -e 'print(admpsw)'`
domain=`$busadmin -l openbus.test.configs -e 'print(domain)'`
baddomain=`$busadmin -l openbus.test.configs -e 'print(baddomain)'`
leasetime=`$busadmin -l openbus.test.configs -e 'print(leasetime)'`
expirationgap=`$busadmin -l openbus.test.configs -e 'print(expirationgap)'`
passwordpenalty=`$busadmin -l openbus.test.configs -e 'print(passwordpenalty)'`
hostname=`$busadmin -l openbus.test.configs -e 'print(bushost)'`

genkey $OPENBUS_TEMP/$name

$buscore \
        -host $hostname \
	-port $port \
	-iorfile $OPENBUS_TEMP/$name.ior \
	-database $OPENBUS_TEMP/$name.db \
	-privatekey $OPENBUS_TEMP/$name.key \
	-certificate $OPENBUS_TEMP/$name.crt \
	-validator $domain:openbus.test.core.services.TesterUserValidator \
	-tokenvalidator $domain:openbus.test.core.services.TestTokenValidator \
	-validator $baddomain:openbus.test.core.services.BadPasswordValidator \
	-tokenvalidator $baddomain:openbus.test.core.services.BadTokenValidator \
	-validator legacydomain:openbus.test.core.services.TryBothValidators \
	-legacydomain legacydomain \
	-admin $admin \
	-badpasswordpenalty $passwordpenalty \
	-leasetime $leasetime \
	-expirationgap $expirationgap \
	-loglevel 5 \
	-logfile $OPENBUS_TEMP/$name.log > $OPENBUS_TEMP/$name.out 2>&1 &
	pid="$pid $!"
	trap "kill $pid > /dev/null 2>&1" 0

$busadmin -e "
	local socket = require 'socket.core'
	for _=1, 10 do
		if assert(socket.tcp()):connect('localhost', $port) then
			break
		end
		socket.sleep(1)
	end
"

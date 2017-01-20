#!/bin/bash

mode=$1

if [[ "$mode" == "" ]]; then
	mode=RELEASE
elif [[ "$mode" != "RELEASE" && "$mode" != "DEBUG" ]]; then
	echo "Usage: $0 [RELEASE|DEBUG]"
	exit 1
fi

runbus="source ${OPENBUS_CORE_TEST}/runbus.sh $mode"
runadmin="source ${OPENBUS_CORE_TEST}/runadmin.sh $mode"
runtests="env \
OPENBUS_CORESDKLUA_HOME=${OPENBUS_LEGACYSDKLUA_HOME} \
OPENBUS_CORESDKLUA_TEST=${OPENBUS_LEGACYSDKLUA_TEST} \
/bin/bash runtests.sh $mode"

busport=21208
leasetime=6
passwordpenalty=6

export OPENBUS_TESTCFG=$OPENBUS_TEMP/test.properties
echo "bus.host.port=$busport"                  > $OPENBUS_TESTCFG
echo "login.lease.time=$leasetime"            >> $OPENBUS_TESTCFG
echo "password.penalty.time=$passwordpenalty" >> $OPENBUS_TESTCFG
#echo "openbus.test.verbose=yes"               >> $OPENBUS_TESTCFG

$runbus BUS01 $busport
genkey $OPENBUS_TEMP/testsyst
$runadmin localhost $busport --script=test.adm
$runtests OpenBus.LoginRegistry
$runtests OpenBus.OfferRegistry
$runadmin localhost $busport --undo-script=test.adm

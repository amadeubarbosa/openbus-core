#!/bin/bash

mode=$1

if [[ "$mode" == "" ]]; then
	mode=RELEASE
elif [[ "$mode" != "RELEASE" && "$mode" != "DEBUG" ]]; then
	echo "Usage: $0 [RELEASE|DEBUG]"
	exit 1
fi

busport=21200
leasetime=6
passwordpenalty=6

export OPENBUS_TESTCFG=$OPENBUS_TEMP/test.properties
echo "bus.host.port=$busport"                  > $OPENBUS_TESTCFG
echo "login.lease.time=$leasetime"            >> $OPENBUS_TESTCFG
echo "password.penalty.time=$passwordpenalty" >> $OPENBUS_TESTCFG
#echo "openbus.test.verbose=yes"               >> $OPENBUS_TESTCFG

source runbus.sh $mode BUS01 $busport
genkey $OPENBUS_TEMP/testsyst
source runadmin.sh $mode localhost $busport --script=test.adm
source runtests.sh $mode
source runadmin.sh $mode localhost $busport --undo-script=test.adm

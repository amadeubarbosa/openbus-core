#!/bin/bash

mode=$1

if [[ "$mode" != "DEBUG" && "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG>"
	exit 1
fi

runconsole="env \
OPENBUS_SDKLUA_HOME=${OPENBUS_CORESDKLUA_HOME} \
OPENBUS_SDKLUA_TEST=${OPENBUS_CORESDKLUA_TEST} \
/bin/bash ${OPENBUS_CORESDKLUA_TEST}/runconsole.sh $mode"

TEST_PRELUDE='package.path=package.path..";"..(os.getenv("OPENBUS_CORE_LUA") or "../lua").."/?.lua"'

if [ "$2" == "" ]; then
	LUACASES="\
	openbus/test/core/services/LoginDB \
	openbus/test/core/Protocol \
	openbus/test/core/admin/admin \
	"
	for case in ${LUACASES}; do
		echo -n "Test '${case}' ... "
		$runconsole -e "$TEST_PRELUDE" ${case}.lua || exit $?
		echo "OK"
	done
fi

TEST_RUNNER="package.path=package.path..';./?.lua'
local suite = require('openbus.test.core.services.Suite')
local Runner = require('loop.test.Results')
local path = {}
for name in string.gmatch('$2', '[^.]+') do
	path[#path+1] = name
end
local runner = Runner{
	reporter = require('loop.test.Reporter'),
	path = (#path > 0) and path or nil,
}
runner('OpenBus', suite)"

$runconsole -e "$TEST_PRELUDE" -e "$TEST_RUNNER" || exit $?

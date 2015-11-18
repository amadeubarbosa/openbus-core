#!/bin/bash

mode=$1

busadmin="env LUA_PATH=${OPENBUS_CORESDKLUA_TEST}/?.lua ${OPENBUS_CORE_HOME}/bin/busadmin"

if [[ "$mode" == "DEBUG" ]]; then
	busadmin="$busadmin DEBUG"
elif [[ "$mode" != "RELEASE" ]]; then
	echo "Usage: $0 <RELEASE|DEBUG>"
	exit 1
fi

TEST_PRELUDE='package.path=package.path..";"..(os.getenv("OPENBUS_CORE_LUA") or "../lua").."/?.lua"'

if [ "$2" == "" ]; then
	LUACASES="\
	openbus/test/core/services/LoginDB \
	openbus/test/core/Protocol \
	openbus/test/core/admin/admin \
	openbus/test/core/admin/Description/descriptor \
	openbus/test/core/admin/Description/loading \
	"
	for case in ${LUACASES}; do
		echo -n "Test '${case}' ... "
		$busadmin -e "$TEST_PRELUDE" ${case}.lua $mode || exit $?
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

$busadmin -e "$TEST_PRELUDE" -e "$TEST_RUNNER" || exit $?

#!/bin/bash

CONSOLE="${OPENBUS_HOME}/bin/busconsole"

if [ "$1" == "DEBUG" ]; then
	CONSOLE="$CONSOLE -d"
elif [ "$1" != "RELEASE" ]; then
	echo "Usage: runall.sh [RELEASE|DEBUG]"
	exit 1
fi

TEST_PRELUDE='package.path=package.path..";"..(os.getenv("OPENBUS_CORE_LUA") or "../lua").."/?.lua"'

LUACASES="\
openbus/test/core/services/LoginDB \
openbus/test/core/Protocol \
openbus/test/core/admin/admin \
"
for case in ${LUACASES}; do
	echo -n "Test '${case}' ... "
	$CONSOLE -e "$TEST_PRELUDE" ${case}.lua || exit $?
	echo "OK"
done

TEST_RUNNER="local suite = require('openbus.test.core.services.Suite')
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

$CONSOLE -e "$TEST_RUNNER" || exit $?

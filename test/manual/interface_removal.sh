#!/bin/bash -e

## This script tests the removal of granted interfaces after a bus restart (bug
## #2342). It is designed to return 0 to the parent process --- e.g., a shell
## --- when the test passes, and 1 when it fails.
##
## It is not yet integrated to the automatic tests infrastructure.

# Common variables
db=db-$$
interface="IDL:x/y:1.0"
privatekey=../testsyst.key
validator=validator-$$.lua

# Create validator script
cat <<! > ${validator}
function validator(name, pass)
  if name == pass then
    return true
  end
  return false
end
return function(configs) return validator end
!

# Define a long busservices execution string
BUSSERVICES="busservices"\
" -loglevel 0"\
" -oilloglevel 0"\
" -database ${db}"\
" -privatekey ${privatekey}"\
" -admin admin"\
" -validator ${validator/%.lua}"

# Same to busadmin
BUSADMIN="busadmin"\
" --login=admin"\
" --password=admin"

# Configure traps
finish() {
  rm -r ${db} ${validator}
  kill -9 ${bus_pid}
}
trap finish INT ABRT KILL TERM EXIT

################################################################################

# Spawn the bus for the first time
${BUSSERVICES} & bus_pid=$!

# Create a category and an entity
${BUSADMIN} --add-category=x --name=x
${BUSADMIN} --add-entity=y --category=x --name=y

# Create an interface
${BUSADMIN} --add-interface=${interface}

# Grant the interface to the entity
${BUSADMIN} --set-authorization=y --grant=${interface}

# Try to remove the interface for the first time (it must fail)
${BUSADMIN} --{login,password}=admin --del-interface=${interface} && exit 1

# Kill the first bus execution
kill -9 ${bus_pid}

# Spawn the bus for the second time
${BUSSERVICES} & bus_pid=$!

# Try to remove the interface for the second time (it must fail too)
${BUSADMIN} --{login,password}=admin --del-interface=${interface} && exit 1

# Great success
exit 0

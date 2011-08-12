#!/bin/ksh

PARAMS=$*

LATT_HOME=${OPENBUS_HOME}/lib/lua/5.1/latt

${OPENBUS_HOME}/bin/servicelauncher ${LATT_HOME}/extras/OiLTestRunner.lua ${PARAMS}

#!/bin/ksh

exec ${OPENBUS_HOME}/core/bin/servicelauncher ${OPENBUS_HOME}/core/services/accesscontrol/AccessControlServer.lua "$@"

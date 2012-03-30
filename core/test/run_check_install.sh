#!/bin/ksh

if [ -z "$OPENBUS_HOME" ]; then
    echo "a vari�vel OPENBUS_HOME n�o est� definida."
    exit 1
fi

echo
echo --- Testes do Openbus ---

echo -n "host:"
read HOST

echo -n "port:"
read PORT

echo Iniciando testes.
${OPENBUS_HOME}/bin/servicelauncher checkInstall.lua $HOST $PORT

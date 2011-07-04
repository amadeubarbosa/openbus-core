#!/bin/ksh
if [ -z "$TEC_UNAME" ]; then
    echo "a variável TEC_UNAME não está definida."
    exit 1
fi

if [ -z "$OPENBUS_HOME" ]; then
    echo "a variável OPENBUS_HOME não está definida."
    exit 1
fi

echo
echo --- Testes do Openbus ---

echo -n "host:"
read HOST

echo -n "port:"
read PORT

echo Iniciando testes.
${OPENBUS_HOME}/core/bin/servicelauncher checkInstall.lua $HOST $PORT

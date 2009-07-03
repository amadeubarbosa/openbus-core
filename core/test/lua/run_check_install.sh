#!/bin/ksh
echo
echo --- Testes do Openbus ---

echo -n "host:"
read HOST

echo -n "port:"
read PORT

echo -n "usuario:"
read USER

echo -n "senha:"
stty -echo
read PASSWORD
stty echo 
echo

echo
echo Iniciando testes.
${OPENBUS_HOME}/core/bin/servicelauncher checkInstall.lua  ${HOST} ${PORT} ${USER} ${PASSWORD}

#!/bin/ksh
TMPFILE=`mktemp`

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

echo props = "{ host ='"${HOST}"',port ='"${PORT}"',user='"${USER}"',password ='"${PASSWORD}"'}" > ${TMPFILE}
chmod 400 ${TMPFILE}

echo
echo Iniciando testes.
${OPENBUS_HOME}/core/bin/servicelauncher checkInstall.lua ${TMPFILE}
rm -f ${TMPFILE}

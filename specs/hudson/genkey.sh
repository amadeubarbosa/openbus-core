#!/bin/ksh

checkOpenSSL ()
{
  which openssl 2> /dev/null 1> /dev/null
  if [ $? == "1" ]; then
    echo "==============================================================================="
    echo "[ERRO] O aplicativo 'openssl' n�o foi encontrado"
    echo "==============================================================================="
    return 1
  fi
}

# Padr�o � usar do host
OPENSSL=openssl
CONFIG=

# OpenBus configurado, usar nossa instala��o. Sen�o, usar do host.
if [ -z "${OPENBUS_HOME}" ]; then
  checkOpenSSL
else
  OPENSSL=${OPENBUS_HOME}/bin/${TEC_UNAME}/openssl
  CONFIG="-config ${OPENSSL_HOME}/openssl.cnf"
  # Verifica se o OpenBus instalou o OpenSSL, caso contr�rio, voltar o padr�o.
  if ! [ -x ${OPENSSL} ]; then
    checkOpenSSL
    OPENSSL=openssl
    CONFIG=
  fi
fi
 
if [ -n "$1" ]; then
  NAME=$1
else
  echo -n "Digite o nome da chave:"
  read NAME
fi

echo "==============================================================================="
echo "[INFO] Gerando certificado: ${NAME}"
echo "==============================================================================="

${OPENSSL} genrsa -out ${NAME}_openssl.key 2048
${OPENSSL} pkcs8 -topk8 -in ${NAME}_openssl.key -nocrypt > ${NAME}.key
${OPENSSL} req ${CONFIG} -new -x509 -key ${NAME}.key -out ${NAME}.crt \
 -outform DER

rm -f ${NAME}_openssl.key

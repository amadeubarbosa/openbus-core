#!/bin/ksh

# Script para geração da chave privada e do certificado digital para
# conexão com o OpenBus.
# 
# $Id$

which openssl > /dev/null 2>&1 || {
  print "comando 'openssl' nao foi encontrado"
  exit 1
}

scriptName=$(basename $0)

function usage {
    cat << EOF

Uso: $scriptName [opcoes]

  onde [opcoes] sao:

  -h      : ajuda
  -c arq  : arquivo de configuracao do OpenSSL
  -n nome : nome do arquivo com o certificado

OBS.: se o nome nao for fornecido via '-n' sera obtido interativamente
EOF
}

while getopts "hc:n:" params; do
     case $params in
        h)
            usage
            exit 0
        ;;
        c)
            sslConfig="-config $OPTARG"
        ;;
        n)
            entityName="$OPTARG"
        ;;
        *)
            usage
            exit 1
        ;;
     esac
done

# descartamos os parametros processados
shift $((OPTIND - 1))

if [ -z "$entityName" ]; then
  echo -n "Nome da chave: "
  read entityName
fi

# se o usuário não especificou um arquivo de configuração para o
# OpenSSL e a variável OPENBUS_HOME está definida, usamos o arquivo de
# configuração do OpenSSL distribuído com o OpenBus
if [ -z "$sslConfig" ]; then
    if [ -n "${OPENBUS_HOME}" ]; then
        # se OPENBUS_HOME está definida, podemos assumir que
        # OPENSSL_HOME também está
        sslConfig="-config ${OPENSSL_HOME}/openssl.cnf"
    fi
fi

print "### Criando certificados para o Openubs ###\n"

openssl genrsa -out ${entityName}_openssl.key 2048
openssl pkcs8 -topk8 -in ${entityName}_openssl.key \
    -nocrypt > ${entityName}.key

openssl req $sslConfig -new -x509 -key ${entityName}.key \
    -out ${entityName}.crt -outform DER

rm -f ${entityName}_openssl.key

print "\nChave privada : ${entityName}.key"
print "Certificado   : ${entityName}.crt"

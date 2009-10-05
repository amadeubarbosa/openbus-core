#!/bin/ksh

if [ -z ${OPENBUS_HOME} ]; then
	echo "[ ERRO ] A variavel OPENBUS_HOME nao foi definida."
	exit 1
fi

if [ -z ${TEC_UNAME} ]; then
	echo "[ ERRO ] A variavel TEC_UNAME nao foi definida. Certifique-se de estar usando a forma Tecmake de identificar o sistema operacional."
	exit 1
fi

OPENBUS_BIN=${OPENBUS_HOME}/core/bin

OPENBUS_DATADIR=${OPENBUS_DATADIR:-${OPENBUS_HOME}/data}
export OPENBUS_DATADIR

if [ -r ${OPENBUS_DATADIR}/conf/config ]; then
  . ${OPENBUS_DATADIR}/conf/config
fi

exec ${OPENBUS_BIN}/$TEC_UNAME/rgs "$@"


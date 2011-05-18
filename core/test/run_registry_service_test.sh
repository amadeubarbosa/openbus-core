#!/bin/ksh

LATT_HOME=${OPENBUS_HOME}/libpath/lua/5.1/latt

ft=0
if [ ! -z $1 ]; then
   if [ $1 != "ft" ]; then
     echo "Para incluir o teste do FT use: run_registry_service_test.sh ft"
     exit
   else
     ft=1
   fi
fi

echo "========================================================================="
echo
echo "                       TESTE DO SERVI�O DE REGISTRO                      "
echo
echo "========================================================================="

./run_unit_test.sh registry/RegistryServiceTestSuite.lua


if [ ${ft} -eq 1 ]; then

  echo "======================================================================="
  echo
  echo "  FT : TESTE DE CONSIST�NCIA DO ESTADO DO SERVI�O DE REGISTRO ENTRE R�PLICAS   "
  echo
  echo "======================================================================="

  ./run_unit_test.sh registry/FTRGSStateConsistencyTestSuite.lua

fi 

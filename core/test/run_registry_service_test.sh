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

echo "==============================================================================="
echo
echo "                   TESTE DA OPERA��O 'REGISTER' DO SERVI�O DE REGISTRO           "
echo
echo "==============================================================================="

./run_unit_test.sh registry/registerTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA OPERA��O 'UNREGISTER' DO SERVI�O DE REGISTRO         "
echo
echo "==============================================================================="

./run_unit_test.sh registry/unregisterTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA OPERA��O 'UPDATE' DO SERVI�O DE REGISTRO           "
echo
echo "==============================================================================="

./run_unit_test.sh registry/updateTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA OPERA��O 'FIND'  DO SERVI�O DE REGISTRO            "
echo
echo "==============================================================================="

./run_unit_test.sh registry/findTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DO USO DO SERVI�O DE REGISTRO SEM CREDENCIAL          "
echo
echo "==============================================================================="

./run_unit_test.sh registry/noCredentialTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA REMO��O DAS OFERTAS AP�S LOGOUT DO CLIENTE         "
echo
echo "==============================================================================="

./run_unit_test.sh registry/logoutTestSuite.lua


if [ ${ft} -eq 1 ]; then

  echo "==============================================================================="
  echo
  echo "  FT : TESTE DE CONSIST�NCIA DO ESTADO DO SERVI�O DE REGISTRO ENTRE R�PLICAS   "
  echo
  echo "==============================================================================="

  ./run_unit_test.sh registry/FTRGSStateConsistencyTestSuite.lua

fi 

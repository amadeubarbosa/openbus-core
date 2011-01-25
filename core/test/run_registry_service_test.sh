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
echo "                   TESTE DA OPERAÇÃO 'REGISTER' DO SERVIÇO DE REGISTRO           "
echo
echo "==============================================================================="

./run_unit_test.sh registry/registerTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA OPERAÇÃO 'UNREGISTER' DO SERVIÇO DE REGISTRO         "
echo
echo "==============================================================================="

./run_unit_test.sh registry/unregisterTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA OPERAÇÃO 'UPDATE' DO SERVIÇO DE REGISTRO           "
echo
echo "==============================================================================="

./run_unit_test.sh registry/updateTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA OPERAÇÃO 'FIND'  DO SERVIÇO DE REGISTRO            "
echo
echo "==============================================================================="

./run_unit_test.sh registry/findTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DO USO DO SERVIÇO DE REGISTRO SEM CREDENCIAL          "
echo
echo "==============================================================================="

./run_unit_test.sh registry/noCredentialTestSuite.lua

echo "==============================================================================="
echo
echo "                   TESTE DA REMOÇÃO DAS OFERTAS APÓS LOGOUT DO CLIENTE         "
echo
echo "==============================================================================="

./run_unit_test.sh registry/logoutTestSuite.lua


if [ ${ft} -eq 1 ]; then

  echo "==============================================================================="
  echo
  echo "  FT : TESTE DE CONSISTÊNCIA DO ESTADO DO SERVIÇO DE REGISTRO ENTRE RÉPLICAS   "
  echo
  echo "==============================================================================="

  ./run_unit_test.sh registry/FTRGSStateConsistencyTestSuite.lua

fi 

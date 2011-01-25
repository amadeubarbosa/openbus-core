#!/bin/ksh

LATT_HOME=${OPENBUS_HOME}/libpath/lua/5.1/latt

ft=0
if [ ! -z $1 ]; then
   if [ $1 != "ft" ]; then
     echo "Para incluir o teste do FT use: run_access_control_service_test.sh ft"
     exit
   else
     ft=1
   fi
fi

echo "========================================================================================"
echo
echo "                   TESTE DO SERVI�O DE CONTROLE DE ACESSO                               "
echo
echo "========================================================================================"

suite=accesscontrol/AccessControlServiceTestSuite.lua
./run_unit_test.sh ${suite}


if [ ${ft} -eq 1 ]; then

  echo "========================================================================================"
  echo
  echo "FT : TESTE DE CONSIST�NCIA DO ESTADO DO SERVI�O DE CONTROLE DE ACESSO ENTRE R�PLICAS    "
  echo
  echo "========================================================================================"

  suite=accesscontrol/FTACSStateConsistencyTestSuite.lua
  ./run_unit_test.sh ${suite}

fi

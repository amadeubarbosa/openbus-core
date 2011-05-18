#!/bin/ksh

LATT_HOME=${OPENBUS_HOME}/libpath/lua/5.1/latt

ft=0
if [ ! -z $1 ]; then
   if [ $1 != "ft" ]; then
     echo "Para incluir o teste do FT use: run_all_test.sh ft"
     exit
   else
     ft=1
   fi
fi

echo "========================================================================="
echo
echo "                   TESTE DO SERVIÇO DE GERÊNCIA                          "
echo
echo "========================================================================="

suite=management/testManagement.lua
./run_unit_test.sh ${suite}

echo "========================================================================="
echo
echo "               TESTE DO SERVIÇO DE CONTROLE DE ACESSO                    "
echo
echo "========================================================================="

suite=accesscontrol/AccessControlServiceTestSuite.lua
./run_unit_test.sh ${suite}

echo "========================================================================="
echo
echo "                   TESTE DO SERVIÇO DE REGISTRO                          "
echo
echo "========================================================================="

suite=registry/RegistryServiceTestSuite.lua
./run_unit_test.sh ${suite}

echo "========================================================================="
echo
echo "                   TESTE DO SERVIÇO DE SESSÃO                            "
echo
echo "========================================================================="

suite=session/testSessionService.lua
./run_unit_test.sh ${suite}


# Sessão de Testes com FT.
if [ ${ft} -eq 1 ]; then

  echo "======================================================================="
  echo
  echo "           FT : TESTE DO SERVIÇO DE CONTROLE DE ACESSO                 "
  echo
  echo "======================================================================="

  suite=accesscontrol/FTACSStateConsistencyTestSuite.lua
  ./run_unit_test.sh ${suite}

  echo "======================================================================="
  echo
  echo "               FT : TESTE DO SERVIÇO DE REGISTRO                        "
  echo
  echo "======================================================================="

  suite=registry/FTRGSStateConsistencyTestSuite.lua
  ./run_unit_test.sh ${suite}

fi

#!/bin/ksh

# Exemplo: run_load_tests.sh accesscontrol/suiteTestIsValid.lua 5 accesscontrol/testOutput

usageMsg="Use: run_load_tests.sh <test_suite_file_name> <nb_of_users> <test_output_folder_path>"

if [ -z $1 ]; then
   echo $usageMsg
   exit
fi

if [ -z $2 ]; then
   echo $usageMsg
   echo "missing <nb_of_users> <test_output_folder_path>"
   exit
fi

if [ -z $3 ]; then
   echo $usageMsg
   echo "missing <test_output_folder_path>"
   exit
fi

if [ ! -f $1 ]; then
 echo "Error: file $1 not found."
 echo $usageMsg
 exit
fi

if [[ $2 != ?([0-9]) ]] ; then
  echo "Error: $2 is not numeric."
  echo $usageMsg
  exit
fi

if [ ! -e $3 ]; then
  echo "Error: directory $3 not found."
  echo $usageMsg
  exit
fi

suite=$1
suite="${suite/.lua/}"
suite=${suite#*/}

echo "=============================================="
echo " LOAD TESTS "
echo "Executing the suite for $2 user(s)..."
for (( i=1; i<=$2; i++ ))
  do
     if [ -f $3"/load_test_output-"${suite}"-"$i".txt" ]; then
       (rm -r $3"/load_test_output-"${suite}"-"$i".txt")
     fi
     (run_unit_test.sh $1 no 2> $3/load_test_output-${suite}-$i.txt &)
done

echo "Waiting the execution to finish..."
wait

echo "Handling the tests output..."

flagC=1
flagW=1

for (( i=1; i<=$2; i++ ))
  do
    TAM="`stat -c "%s" "$3"/load_test_output-"${suite}"-"$i".txt 2>/dev/null || echo "0"`"
    if [ $TAM -gt 0 ]; then
      if [ $flagC -eq 1 ]; then
          echo "Some tests with failures. Check the file(s): "
          echo "=> "$3"/load_test_output-"${suite}"-"$i".txt ";
          flagC=0
      else
          echo "=> "$3"/load_test_output-"${suite}"-"$i".txt "
      fi
    else
      #if [ $flagW -eq 1 ]; then
      #    echo "The following file(s) were removed:";
      #    echo "=> "$3"/load_test_output-"${suite}"-"$i".txt ";
      #    flagW=0
      #else
      #    echo "=> "$3"/load_test_output-"${suite}"-"$i".txt"
      #fi
      rm -r $3/load_test_output-${suite}-$i.txt
    fi
done
if [ $flagC -eq 1 ]; then
  echo " TESTS OK!"
else
  echo " TESTS FAILED!"
fi

echo "The End."
echo "=============================================="
exit



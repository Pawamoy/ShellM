#!/bin/bash

success=0
failure=1
status=${success}

echo "----------------------- Checking test script ----------------------"
shellcheck "$0" || status=${failure}
echo "----------------------- Checking shellm/bin -----------------------"
shellcheck bin/{dbg,del,mod,new,ren,xrun} || status=${failure}
echo "----------------------- Checking shellm/lib -----------------------"
find lib -name '*.sh' -exec shellcheck -e SC2148 {} + || status=${failure}

[ ${status} -eq 0 ] &&
  echo -e "\e[;1;92mSuccess! All tests passed.\e[;0m" ||
  echo -e "\e[;1;33mFailure... Some tests failed.\e[;0m"
exit ${status}

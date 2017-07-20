#!/bin/bash

. "${BATS_TEST_DIRNAME}/../init.sh"

scripts=$(file bin/* | grep 'shell script' | cut -d: -f1)
libs=$(find lib -name '*.sh')

success=0
failure=1

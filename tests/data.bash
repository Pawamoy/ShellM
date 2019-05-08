#!/bin/bash

load $(basher package-path ztombol/bats-support)/load.bash
load $(basher package-path ztombol/bats-assert)/load.bash

LIBPATH="${BATS_TEST_DIRNAME}/fixtures/lib"
. "${BATS_TEST_DIRNAME}/../lib/shellm.bash"

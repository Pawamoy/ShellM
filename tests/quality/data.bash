#!/usr/bin/env bash

. "${BATS_TEST_DIRNAME}/../../lib/shellm.bash"

readarray -t scripts <<<"$(file commands/* | grep -E 'sh(ell)? script' | cut -d: -f1)"
readarray -t libs <<<"$(find lib -name '*sh')"

success=0
failure=1

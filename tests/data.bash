#!/bin/bash

. "${BATS_TEST_DIRNAME}/../init.sh"

export SHELLS="bash-4.4.12 zsh-5.4.2"

scripts=$(file bin/* | grep -E 'sh(ell)? script' | cut -d: -f1)
libs=""

success=0
failure=1

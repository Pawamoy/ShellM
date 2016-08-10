#!/bin/bash

include core/format.sh

# shellcheck disable=SC2154
scripts=$(file bin/* | grep 'shell script' | cut -d: -f1)
libs=$(find lib -name '*.sh')
shells=(zsh ksh bash dash sh)

success=0
failure=1

check_shells() {
  local output script status=${success}
  for script in "$@"; do
    for shell in "${shells[@]}"; do
      if command -v "${shell}" >/dev/null; then
        output=$(${shell} -n "${script}" 2>&1) || status=${failure}
        if [ -n "${output}" ]; then
          format u -- "${script}"
          format R -- :
          format m -- "${shell}\n"
          echo "${output}"
        fi
      fi
    done
  done
  return ${status}
}

bashism() {
  checkbashisms -fpx "$@" 2>&1 | sed 's/possible bashism in /'"$(format w)"'/g;s/$/'"$(format R)"'/g;s/^script/'"$(format w)"'script/g'
  # shellcheck disable=SC2086
  return ${PIPESTATUS[0]}
}

lint_suite() {
  local status=${success}
  format B -- "==============================================================\n"
  format B -- "=                       $1\n"
  format B -- "==============================================================\n"
  echo
  format y -- "-------------------- Checking test script --------------------\n"
  ${lint_script_command} "$0" || status=${failure}
  format y -- "-------------------- Checking shellm/bin ---------------------\n"
  # shellcheck disable=SC2086
  ${lint_bin_command} ${scripts} || status=${failure}
  format y -- "-------------------- Checking shellm/lib ---------------------\n"
  # shellcheck disable=SC2086
  ${lint_lib_command} ${libs} || status=${failure}

  # shellcheck disable=SC2015
  [ ${status} -eq 0 ] &&
    format B g -- "Success! All tests passed.\n" ||
    format B r -- "Failure... Some tests failed.\n"

  echo
  return ${status}
}

lint() {
  # font stop on http://patorjk.com/software/taag/#p=display&f=Stop&t=unit%20tests
  format B c -- "
   _ _            _
  | (_)      _   (_)
  | |_ ____ | |_  _ ____   ____
  | | |  _ \|  _)| |  _ \ / _  |
  | | | | | | |__| | | | ( ( | |
  |_|_|_| |_|\___)_|_| |_|\_|| |
                         (_____|\n\n"

  local final_status=${success}

  lint_script_command=shellcheck
  lint_bin_command=shellcheck
  lint_lib_command="shellcheck -e SC2148"
  lint_suite "SHELLCHECK" || final_status=${failure}

  lint_script_command=bashism
  lint_bin_command=bashism
  lint_lib_command=bashism
  lint_suite "CHECKBASHISMS" || final_status=${failure}

  lint_script_command=check_shells
  lint_bin_command=check_shells
  lint_lib_command=check_shells
  lint_suite "COMPATIBILITY" || final_status=${failure}

  return ${final_status}
}

main() {
  lint
}

main "$@"

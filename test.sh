#!/bin/bash

## \brief Test suite for shellm
## \desc Options are cumulative, you can disable all tests then reactivate one.
## By default, all tests are run.

include core/format.sh
include core/shellman.sh

success=0
failure=1

# all_shells=(ash bash bosh bsh csh dash fish ksh mksh posh scsh sh tcsh xonsh yash zsh)
shells="bash sh zsh"

check_files_suite() {
  local status=${success}
  format B nl -- "============================================================="
  format B nl -- "=                       $1"
  format B nl -- "============================================================="
  echo
  if [ "${check_script_command}" = "true" ]; then
    format nl -- "-------------------- Ignore test script ---------------------"
  else
    format y nl -- "-------------------- Checking test script -------------------"
    ${check_script_command} "$0" || status=${failure}
  fi
  if [ "${check_bin_command}" = "true" ]; then
    format nl -- "-------------------- Ignore scripts -------------------------"
  else
    format y nl -- "-------------------- Checking scripts -----------------------"
    # shellcheck disable=SC2086
    ${check_bin_command} ${scripts} || status=${failure}
  fi
  if [ "${check_lib_command}" = "true" ]; then
    format nl -- "-------------------- Ignore libraries -----------------------"
  else
    format y nl -- "-------------------- Checking libraries ---------------------"
    # shellcheck disable=SC2086
    ${check_lib_command} ${libs} || status=${failure}
  fi

  # shellcheck disable=SC2015
  [ ${status} -eq 0 ] &&
    format B g -- "Success! All tests passed.\n" ||
    format B r -- "Failure... Some tests failed.\n"

  echo
  return ${status}
}

linting() {
  # font stop on http://patorjk.com/software/taag/#p=display&f=Stop&t=linting
  format B c nl -- "
   _ _            _
  | (_)      _   (_)
  | |_ ____ | |_  _ ____   ____
  | | |  _ \|  _)| |  _ \ / _  |
  | | | | | | |__| | | | ( ( | |
  |_|_|_| |_|\___)_|_| |_|\_|| |
                         (_____|
  "

  local status=${success}

  check_script_command=shellcheck
  check_bin_command=shellcheck
  check_lib_command="shellcheck -e SC2148"
  check_files_suite "SHELLCHECK" || status=${failure}

  return ${status}
}

# shellcheck disable=SC2120
compatibility() {
  # http://patorjk.com/software/taag/#p=display&f=Stop&t=compatibility
  format B c nl -- "
                                     _ _     _ _ _
                                _   (_) |   (_) (_)_
    ____ ___  ____  ____   ____| |_  _| | _  _| |_| |_ _   _
   / ___) _ \|    \|  _ \ / _  |  _)| | || \| | | |  _) | | |
  ( (__| |_| | | | | | | ( ( | | |__| | |_) ) | | | |_| |_| |
   \____)___/|_|_|_| ||_/ \_||_|\___)_|____/|_|_|_|\___)__  |
                   |_|                                (____/
  "

  bashism() {
    checkbashisms -fpx "$@" 2>&1 | sed 's/possible bashism in /'"$(format iy)"'/g;s/$/'"$(format RA)"'/g;s/^script/'"$(format iy)"'script/g'
    # shellcheck disable=SC2086
    return ${PIPESTATUS[0]}
  }

  check_shells() {
    local output script status=${success}
    for script in "$@"; do
     for shell in ${shells}; do
       if command -v "${shell}" >/dev/null; then
         output=$(${shell} -nv "${script}" 2>&1)
         if [ $? -ne 0 ]; then
           status=${failure}
           echo "$(format ib -- "${script}"):$(format m -- "${shell}")"
           echo "${output}" | tail -n2
         fi
       fi
     done
    done
    return ${status}
  }

  local status=${success}

  check_script_command=bashism
  check_bin_command=bashism
  check_lib_command=bashism
  check_files_suite "CHECKBASHISMS" || status=${failure}

  check_script_command=check_shells
  check_bin_command=check_shells
  check_lib_command=check_shells
  check_files_suite "SHELLS (${shells[*]})" || status=${failure}

  return ${status}
}

# shellcheck disable=SC2120
documentation() {
  # font stop on http://patorjk.com/software/taag/#p=display&f=Stop&t=documentation
  format B c nl -- "
       _                                                    _
      | |                                    _         _   (_)
    _ | | ___   ____ _   _ ____   ____ ____ | |_  ____| |_  _  ___  ____
   / || |/ _ \ / ___) | | |    \ / _  )  _ \|  _)/ _  |  _)| |/ _ \|  _ \\
  ( (_| | |_| ( (___| |_| | | | ( (/ /| | | | |_( ( | | |__| | |_| | | | |
   \____|\___/ \____)\____|_|_|_|\____)_| |_|\___)_||_|\___)_|\___/|_| |_|
   "

  check_tag() {
    local script status=${success}
    for script in "$@"; do
      if ! shellman_get "${checked_tag}" "${script}" >/dev/null; then
        echo "$(format ib -- "${script}"): missing tag $(format B "${checked_tag}")"
        status=${failure}
      fi
    done
    return ${status}
  }

  check_help() {
    local script status=${success}
    for script in "$@"; do
      [ "$(basename "${script}")" = "xrun" ] && continue
      if ! "${script}" --help >/dev/null; then
        echo "$(format ib -- "${script}"): no help option"
        status=${failure}
      fi
    done
    return ${status}
  }

  local status=${success}

  check_script_command=check_tag
  check_bin_command=check_tag
  check_lib_command=true # ignore usage for libs

  checked_tag='usage'
  check_files_suite "USAGE" || status=${failure}

  check_lib_command=check_tag

  # FIXME: should not succeed if only fn-brief is found...
  checked_tag='brief'
  check_files_suite "BRIEF" || status=${failure}

  # This could be harmful!
  # check_script_command=check_help
  # check_bin_command=check_help
  # check_lib_command=true # ignore help for libs
  #
  # check_files_suite "HELP OPTION" || status=${failure}

  return ${status}
}

# shellcheck disable=SC2120
libraries() {
  # font stop on http://patorjk.com/software/taag/#p=display&f=Stop&t=libraries
  format B c nl -- "
   _ _ _                      _
  | (_) |                    (_)
  | |_| | _   ____ ____  ____ _  ____  ___
  | | | || \ / ___) _  |/ ___) |/ _  )/___)
  | | | |_) ) |  ( ( | | |   | ( (/ /|___ |
  |_|_|____/|_|   \_||_|_|   |_|\____|___/
  "

  check_if_ndef_define_fi() {
    local ifndef_clause define_clause def1 def2 expected lib status=${success}
    for lib in "$@"; do
      [ "${lib}" = "lib/core/include.sh" ] && continue
      ifndef_clause=$(grep -E '^[[:space:]]*if[[:space:]]+ndef[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*' "${lib}")
      define_clause=$(grep -E '^[[:space:]]*define[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*' "${lib}")
      if [ ! -n "${ifndef_clause}" ] ; then
        status=${failure}
        echo "$(format ib -- "${lib}"): missing $(format B -- 'if ndef' clause)"
      fi
      if [ ! -n "${define_clause}" ] ; then
        status=${failure}
        echo "$(format ib -- "${lib}"): missing $(format B -- 'define' clause)"
      fi
      def1=$(echo "${ifndef_clause}" | tr -s ' ' | cut -d' ' -f3 | sed 's/\;//g')
      def2=$(echo "${define_clause}" | tr -s ' ' | cut -d' ' -f2)
      if [ "${def1}" != "${def2}" ]; then
        status=${failure}
        echo "$(format iy -- "${lib}"): define don't match ifndef $(format B -- "${def1} / ${def2}")"
      fi
      expected=${lib#lib/}
      expected=${expected^^}
      expected=${expected//\//_}
      expected=__${expected//./_}
      if [ "${def1}" != "${expected}" ]; then
        status=${failure}
        echo "$(format ir -- "${lib}"): define should be $(format B -- "${expected}")"
      fi
    done
    return ${status}
  }

  local status=${success}

  check_script_command=true
  check_bin_command=true
  check_lib_command=check_if_ndef_define_fi
  check_files_suite "IFNDEF / DEFINE" || status=${failure}

  return ${status}
}

main() {
  local LINTING=true
  local COMPATIBILITY=true
  local DOCUMENTATION=true
  local LIBRARY=true
  local USR=false
  while [ $# -ne 0 ]; do
    case "$1" in
      ## \option -a, --all
      ## Run all the tests.
      -a|--all)
        LINTING=true
        COMPATIBILITY=true
        DOCUMENTATION=true
      ;;
      ## \option -n, --none
      ## Disable all the tests.
      -n|--none)
        LINTING=false
        COMPATIBILITY=false
        DOCUMENTATION=false
        LIBRARY=false
      ;;
      ## \option -l, --linting
      ## Run the linting tests.
      -l|--linting) LINTING=true ;;
      ## \option -c, --compatibility
      ## Run the compatibility tests.
      -c|--compatibility) COMPATIBILITY=true ;;
      ## \option -d, --documentation
      ## Run the documentation tests.
      -d|--documentation) DOCUMENTATION=true ;;
      ## \option -b, --library
      ## Run the library tests.
      -b|--library) LIBRARY=true ;;
      ## \option -L, --no-linting
      ## Don't run the linting tests.
      -L|--no-linting) LINTING=false ;;
      ## \option -c, --compatibility
      ## Don't run the compatibility tests.
      -C|--no-compatibility) COMPATIBILITY=false ;;
      ## \option -d, --documentation
      ## Don't run the documentation tests.
      -D|--no-documentation) DOCUMENTATION=false ;;
      ## \option -B, --no-library
      ## Don't run the library tests.
      -B|--no-library) LIBRARY=false ;;
      ## \option -u, --user
      ## Run the tests in the usr directory.
      -u|--user) USR=true ;;
      ## \option -h, --help
      ## Print this help and exit.
      -h|--help) shellman -t "$0"; exit 0 ;;
    esac
    shift
  done

  if ${USR}; then
    # shellcheck disable=SC2154
    cd "${shellm}/usr"
    echo "(running tests in user directory: $(pwd))"
  fi

  # shellcheck disable=SC2154
  scripts=$(file bin/* | grep 'shell script' | cut -d: -f1)
  libs=$(find lib -name '*.sh')

  local status=${success}

  if ${LINTING}; then
    linting || status=${failure}
  fi
  # shellcheck disable=SC2119
  if ${COMPATIBILITY}; then
    compatibility || status=${failure}
  fi
  # shellcheck disable=SC2119
  if ${DOCUMENTATION}; then
    documentation || status=${failure}
  fi
  # shellcheck disable=SC2119
  if ${LIBRARY}; then
    libraries || status=${failure}
  fi

  return ${status}
}

## \usage ./test.sh [-h] | [-anlcdLCDu]
main "$@"

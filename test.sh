#!/bin/bash

## \brief Test suite for shellm
## \desc Options are cumulative, you can disable all tests then reactivate one.
## By default, all tests are run.
## \require shellcheck checkbashisms zsh

include core/format.sh
include core/shellman.sh

success=0
failure=1

shells="ash bash bosh bsh csh dash fish ksh mksh posh scsh sh tcsh xonsh yash zsh"

check_files_suite() {
  local status=${success}
  if ${VERBOSE}; then
    format B nl -- "============================================================="
    format B nl -- "=                       $1"
    format B nl -- "============================================================="
    echo
  else
    format B nl -- "======================= $1"
  fi
  if [ "${check_script_command}" = "true" ]; then
    format nl -- "-------------------- Ignore test script ---------------------"
  elif [ ! -f "${test_script}" ]; then
    format nl -- "-------------------- No user test script --------------------"
  else
    format y nl -- "-------------------- Checking test script -------------------"
    ${check_script_command} "${test_script}" || status=${failure}
  fi
  if [ "${check_bin_command}" = "true" ]; then
    format nl -- "-------------------- Ignore scripts -------------------------"
  elif [ ! -n "${scripts}" ]; then
    format nl -- "-------------------- No scripts -----------------------------"
  else
    format y nl -- "-------------------- Checking scripts -----------------------"
    # shellcheck disable=SC2086
    ${check_bin_command} ${scripts} || status=${failure}
  fi
  if [ "${check_lib_command}" = "true" ]; then
    format nl -- "-------------------- Ignore libraries -----------------------"
  elif [ ! -n "${libs}" ]; then
    format nl -- "-------------------- No libraries -----------------------------"
  else
    format y nl -- "-------------------- Checking libraries ---------------------"
    # shellcheck disable=SC2086
    ${check_lib_command} ${libs} || status=${failure}
  fi

  echo
  return ${status}
}

linting() {
  if ! command -v shellcheck >/dev/null; then
    echo "shellcheck not found: don't test linting" >&2
    return 0
  fi
  # font stop on http://patorjk.com/software/taag/#p=display&f=Stop&t=linting
  ${VERBOSE} && format ic nl -- "
   _ _            _
  | (_)      _   (_)
  | |_ ____ | |_  _ ____   ____
  | | |  _ \|  _)| |  _ \ / _  |
  | | | | | | |__| | | | ( ( | |
  |_|_|_| |_|\___)_|_| |_|\_|| |
                         (_____|
  "

  local status=${success}

  check_script_command="shellcheck -x -C${SHELLCHECK_COLOR}"
  check_bin_command="shellcheck -x -C${SHELLCHECK_COLOR}"
  check_lib_command="shellcheck -xe SC2148 -C${SHELLCHECK_COLOR}"
  check_files_suite "SHELLCHECK" || status=${failure}

  return ${status}
}

# shellcheck disable=SC2120
compatibility() {
  if ! command -v checkbashisms >/dev/null; then
    echo "checkbashisms not found: don't test compatibility" >&2
    return 0
  fi
  # http://patorjk.com/software/taag/#p=display&f=Stop&t=compatibility
  ${VERBOSE} && format ic nl -- "
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
         if ! output=$(${shell} -nv "${script}" 2>&1); then
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
  check_files_suite "RUNS ON SHELLS (${shells[*]})" || status=${failure}

  return ${status}
}

# shellcheck disable=SC2120
documentation() {
  # font stop on http://patorjk.com/software/taag/#p=display&f=Stop&t=documentation
  ${VERBOSE} && format ic nl -- "
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

  check_usage_matches_script_name() {
    local script usage usages status=${success}
    for script in "$@"; do
      if usages=$(shellman_get "usage" "${script}" | cut -d' ' -f1); then
        for usage in ${usages}; do
          if [ "${usage}" != "$(basename "${script}")" ]; then
            echo "$(format ib -- "${script}"): usage '$(format B "${usage}")' does not match script name"
            status=${failure}
          fi
        done
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

  check_shellman_documentation() {
    local script status=${success}
    for script in "$@"; do
      if ! shellman -cwi "require,export" "${script}"; then
        # echo "$(format ib -- "${script}"): no help option"
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
  check_files_suite "HAS USAGE" || status=${failure}

  check_script_command=check_usage_matches_script_name
  check_bin_command=check_usage_matches_script_name
  check_files_suite "USAGE MATCHES SCRIPT" || status=${failure}

  check_lib_command=check_tag

  # FIXME: should not succeed if only fn-brief is found...
  check_script_command=check_tag
  check_bin_command=check_tag
  checked_tag='brief'
  check_files_suite "HAS BRIEF" || status=${failure}

  check_script_command=check_shellman_documentation
  check_bin_command=check_shellman_documentation
  check_lib_command=check_shellman_documentation
  check_files_suite "SHELLMAN DOCUMENTATION" || status=${failure}

  # This could be harmful!
  # check_script_command=check_help
  # check_bin_command=check_help
  # check_lib_command=true # ignore help for libs
  #
  # check_files_suite "HELP OPTION" || status=${failure}

  return ${status}
}

# shellcheck disable=SC2120
library() {
  # font stop on http://patorjk.com/software/taag/#p=display&f=Stop&t=libraries
  ${VERBOSE} && format ic nl -- "
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

  check_declare_contents() {
    local lib status=${success}
    for lib in "$@"; do
      [ "${lib}" = "lib/core/include.sh" ] && continue
      if ! grep -Eq 'define[[:space:]]+[^"]+"' "$lib"; then
        status=${failure}
        echo "$(format ir -- "${lib}"): define should declare contents between double-quotes"
      fi
    done

    return ${status}
  }

  check_namespace_clashes() {
    local lib contents declarations status=${success}
    declarations=$(
      for lib in "$@"; do
        contents=$(pcregrep -M 'define\s+[^"]*"(\n|[^"])*"' "$lib")
        contents=${contents#*\"}
        contents=${contents%\"*}

        for content in ${contents}; do
          echo "('${content}','${lib}'),"
        done
      done
    )

    python_code="
m = {}
for d, f in [${declarations}]:
    if m.get(d, None) is None:
        m[d] = [f]
    else:
        m[d].append(f)

for d, f in m.items():
    if len(f) > 1:
        print('%s:%s' % (d, ','.join(f)))
    "

    local clash clashes declaration files
    clashes="$(python -c "${python_code}")"
    if [ -n "${clashes}" ]; then
      status=${failure}
      for clash in ${clashes}; do
        declaration=${clash%%:*}
        files=${clash#*:}
        echo "$(format ir -- "${declaration}"): declaration clashes between files $(format B -- "${files}")"
      done
    fi

    return ${status}
  }

  local status=${success}

  check_script_command=true
  check_bin_command=true

  check_lib_command=check_if_ndef_define_fi
  check_files_suite "IFNDEF / DEFINE" || status=${failure}

  check_lib_command=check_declare_contents
  check_files_suite "DECLARED CONTENTS" || status=${failure}

  if [ ${status} -eq 0 ]; then
    check_lib_command=check_namespace_clashes
    check_files_suite "NAMESPACE CLASHES" || status=${failure}
  fi

  return ${status}
}

main() {
  local LINTING=true
  local COMPATIBILITY=true
  local DOCUMENTATION=true
  local LIBRARY=true
  local USR=false
  local VERBOSE=true

  SHELLCHECK_COLOR="auto"
  while [ $# -ne 0 ]; do
    case "$1" in
      ## \option -a, --all
      ## Run all the tests.
      -a|--all)
        LINTING=true
        COMPATIBILITY=true
        DOCUMENTATION=true
      ;;
      ## \option -b, --library
      ## Run the library tests.
      -b|--library) LIBRARY=true ;;
      ## \option -B, --no-library
      ## Don't run the library tests.
      -B|--no-library) LIBRARY=false ;;
      ## \option -c, --compatibility
      ## Run the compatibility tests.
      -c|--compatibility) COMPATIBILITY=true ;;
      ## \option -c, --no-compatibility
      ## Don't run the compatibility tests.
      -C|--no-compatibility) COMPATIBILITY=false ;;
      ## \option -d, --documentation
      ## Run the documentation tests.
      -d|--documentation) DOCUMENTATION=true ;;
      ## \option -d, --no-documentation
      ## Don't run the documentation tests.
      -D|--no-documentation) DOCUMENTATION=false ;;
      ## \option -h, --help
      ## Print this help and exit.
      -h|--help) shellman "$0"; exit 0 ;;
      ## \option -l, --linting
      ## Run the linting tests.
      -l|--linting) LINTING=true ;;
      ## \option -L, --no-linting
      ## Don't run the linting tests.
      -L|--no-linting) LINTING=false ;;
      ## \option -n, --none
      ## Disable all the tests.
      -n|--none)
        LINTING=false
        COMPATIBILITY=false
        DOCUMENTATION=false
        LIBRARY=false
      ;;
      ## \option -p, --plain-text, --no-color
      ## Don't use colors.
      -p|--plain-text|--no-color)
        # shellcheck disable=SC2034
        SHELLM_NO_FORMAT=true
        SHELLCHECK_COLOR="never"
      ;;
      ## \option -q, --quiet
      ## Reduce output.
      -q|--quiet) VERBOSE=false ;;
      ## \option -u, --user
      ## Run the tests in the user directory.
      -u|--user) USR=true ;;
      ## \option -v, --verbose
      ## Be more verbose.
      -v|--verbose) VERBOSE=true ;;
    esac
    shift
  done

  test_script="$0"

  if ${USR} && [ -d "${SHELLM_USR}" ]; then
    # shellcheck disable=SC2154
    if ! cd "${SHELLM_USR}"; then
      echo "test.sh: can't cd into user directory, abort" >&2
      exit 1
    fi
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
    library || status=${failure}
  fi

  if ${USR} && [ -f "${test_script}" ]; then
    # shellcheck disable=SC2086
    ./"${test_script}" ${USR_OPTS} || status=${failure}
  fi

  # FIXME: also test shellmrc !!!

  # shellcheck disable=SC2015
  [ ${status} -eq 0 ] &&
    format B g -- "Success! All tests passed.\n" ||
    format B r -- "Failure... Some tests failed.\n"

  return ${status}
}

## \usage test.sh [-h] | [-anlLcCdDu]
main "$@"

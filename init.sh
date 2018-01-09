# shellcheck disable=SC2148
# Shellm functions -------------------------------------------------------------
## TODO: add docs
shellm() {
  local cmd="$1"

  if command -v "shellm-${cmd}" &>/dev/null; then
    shift
    # shellcheck disable=SC2086
    shellm-${cmd} "$@"
  elif command -v "${cmd}" &>/dev/null; then
    ( cd "${SHELLM_USR}" && "$@" )
  else
    echo "shellm: unknown command '${cmd}'" >&2
    return 1
  fi
}
export -f shellm

## \fn find-script [NAME]
## \brief Find a script.
shellm-find-script() {
  local arg
  if [ $# -eq 1 ]; then
    arg="$1"
  else
    arg="$0"
  fi
  type -p "${arg}"
}
export -f shellm-find-script

## \fn find-lib <NAME>
## \brief Find a library file.
shellm-find-lib() {
  local libdir
  IFS=':' read -r -a array <<< "${LIBPATH}"
  for libdir in "${array[@]}"; do
    if [ -f "${libdir}/$1" ]; then
      echo "${libdir}/$1"
      return 0
    fi
  done
  return 1
}
export -f shellm-find-lib

## \fn shellm-ndef
## \brief Tests if a variable is set (non-empty)
## \return true if empty (unset), false otherwise
shellm-ndef() {
  # shellcheck disable=SC2086
  local key
  if ! [ -z "${_SHELLM_INCLUDED[@]+x}" ]; then
    for key in "${!_SHELLM_INCLUDED[@]}"; do
      if [ "${key}" = "${__SHELLM_LIBSTACK[-1]}" ]; then
        return 1
      fi
    done
  else
    declare -gA _SHELLM_INCLUDED
  fi
  return 0
}
export -f shellm-ndef

## \fn shellm-define (name, [value])
## \brief Defines an environment variable in the current shell
## \param name Variable name
## \param value Optional, variable content (default: 'def')
## \return false if no args or error while affectation, true otherwise
shellm-define() {
  _SHELLM_INCLUDED+=(["${__SHELLM_LIBSTACK[-1]}"]="$1")
}
export -f shellm-define

# TODO: move elsewhere
_shellm_die() {
  case "${WINDOWID}" in
    [0-9]*) [ ${SHLVL} -gt 2 ] && exit $1 || return $1 ;;
    "") [ ${SHLVL} -gt 1 ] && exit $1 || return $1 ;;
  esac
}

## \fn shellm-include (filename)
## \brief Includes content of a library file in the current shell
## \param filename Name of library file to include
## \stderr Message if return code 1
## \return false (and exits if subshell) if no args or error while including contents, true otherwise
shellm-include() {
  local libdir array arg lib status

  # compatibility with basher
  if [ $# -eq 2 ]; then
    arg="$1/$2"
  else
    arg="$1"
  fi

  if lib="$(shellm-find-lib "${arg}")"; then
    __SHELLM_LIBSTACK+=("${lib}")

    # shellcheck disable=SC1090
    . "${lib}"
    status=$?

    unset __SHELLM_LIBSTACK[-1]

    if [ ${status} -ne 0 ]; then
      echo "shellm-include: error while including ${lib}" >&2
      echo "  command: $0" >&2
      echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
      return 1
    fi
  else
    echo "shellm-include: no such file in LIBPATH: ${arg}" >&2
    echo "  command: $0" >&2
    echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
    return 1
  fi
}
export -f shellm-include

shellm-exclude() {
  local current_lib arg include includes lib_header def defined

  # compatibility with basher
  if [ $# -eq 2 ]; then
    arg="$1/$2"
  else
    arg="$1"
  fi

  if ! current_lib="$(shellm-find-lib "${arg}")"; then
    echo "shellm-exclude: no such file in LIBPATH: ${arg} (from $0)" >&2
    return 1
  fi

  lib_header=${current_lib#${SHELLM_USR}/lib/}
  lib_header=${lib_header//[\/.]/_}
  lib_header=__${lib_header^^}
  defined=${!lib_header}
  for def in ${defined}; do
    case "$(type -t "${def}")" in
      function)
        # shellcheck disable=SC2163
        unset -f "${def}"
      ;;
      alias)
        # shellcheck disable=SC2163
        unalias "${def}"
      ;;
      "")
        # shellcheck disable=SC2163
        unset "${def}"
      ;;
    esac
  done
  unset "${lib_header}"

  # recurse on other included libraries
  # FIXME: #8 fix incomplete regex
  includes=$(grep -Eo "(shellm[- ])?include [\"']?[a-zA-Z_/]*\.sh[\"']?" "${current_lib}" | cut -d' ' -f2 | sed "s/[\"']//g")
  for include in ${includes}; do
    shellm-exclude "${include}"
  done
}
export -f shellm-exclude

# Setup variables --------------------------------------------------------------
declare -a __SHELLM_LIBSTACK

if [ -d "/usr/local/packages" ]; then
  LIBPATH="/usr/local/packages:${LIBPATH}"
fi

if [ -d "${HOME}/.basher/cellar/packages" ]; then
  LIBPATH="${HOME}/.basher/cellar/packages:${LIBPATH}"
fi

export LIBPATH

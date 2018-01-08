# shellcheck disable=SC2148
# Shellm functions -------------------------------------------------------------
## TODO: add docs
shellm() {
  local cmd="$1"

  if command -v "shellm-${cmd}" >/dev/null; then
    shift
    # shellcheck disable=SC2086
    shellm-${cmd} "$@"
  else
    ( cd "${SHELLM_USR}" && "$@" )
  fi
}

## TODO: add docs
shellm-load() {
  if [ $# -gt 1 ]; then
    echo "shellm-load: too many arguments" >&2
    return 1
  elif [ $# -eq 1 ]; then
    if [ -f "$1" ]; then
      SHELLM_PROFILE="$(readlink -f "$1")"
    else
      echo "shellm-load: no such file: $1 (from argument 1)"
    fi
  elif [ -n "${SHELLM_PROFILE}" ]; then
    if [ -f "${SHELLM_PROFILE}" ]; then
      SHELLM_PROFILE="$(readlink -f "${SHELLM_PROFILE}")"
    else
      echo "shellm-load: no such file: ${SHELLM_PROFILE} (from SHELLM_PROFILE variable)"
    fi
  elif [ -f "${HOME}/.shellm-profile" ]; then
    SHELLM_PROFILE="$(readlink -f "${HOME}/.shellm-profile")"
  else
    echo "shellm-load: no profile loaded, try 'shellm help load' to see how profiles are loaded" >&2
    return 1
  fi

  SHELLM_USR="$(dirname "${SHELLM_PROFILE}")"
  export SHELLM_PROFILE SHELLM_USR

  if ! echo "${PATH}" | grep -q "${SHELLM_USR}/bin"; then
    export PATH="${SHELLM_USR}/bin:${PATH}"
  fi

  export MANPATH="${SHELLM_USR}/man:${MANPATH}"
  export LIBPATH="${SHELLM_USR}/lib:${LIBPATH}"

  # shellcheck disable=SC1090
  . "${SHELLM_PROFILE}"
}

## TODO: add docs
shellm-cd() {
  # shellcheck disable=SC2164
  cd "${SHELLM_USR}/$1"
}

## \fn shellm-define (name, [value])
## \brief Defines an environment variable in the current shell
## \param name Variable name
## \param value Optional, variable content (default: 'def')
## \return false if no args or error while affectation, true otherwise
shellm-define() {
  if [ $# -eq 2 ]; then
    declare -r "$1"="$2"
  elif [ $# -eq 1 ]; then
    declare -r "$1"
  else
    echo "shellm-define: usage: shellm-define <VARNAME> [VALUE]" >&2
    return 1
  fi
}

# TODO: move elsewhere
_shellm_die() {
  case "${WINDOWID}" in
    [0-9]*) [ ${SHLVL} -gt 2 ] && exit $1 || return $1 ;;
    "") [ ${SHLVL} -gt 1 ] && exit $1 || return $1 ;;
  esac
}

## \fn find_script [NAME]
## \brief Find a script.
find_script() {
  local found
  if [ $# -eq 1 ]; then
    if [ -f "$1" ]; then
      found="$1"
    elif [ -f "${SHELLM_USR}/bin/$1" ]; then
      found="${SHELLM_USR}/bin/$1"
    else
      echo "find_script: can't find $1" >&2
      return 1
    fi
  elif [ -f "$0" ]; then
    found="$0"
  elif [ -f "${SHELLM_USR}/bin/$0" ]; then
    found="${SHELLM_USR}/bin/$0"
  else
    echo "find_script: can't find $0" >&2
    return 1
  fi

  echo "${found}"
}

## \fn find_lib <NAME>
## \brief Find a library file.
find_lib() {
  local found
  if [ -f "$1" ]; then
    found="$1"
  elif [ -f "${SHELLM_USR}/lib/$1" ]; then
    found="${SHELLM_USR}/lib/$1"
  else
    echo "find_lib: can't find $1" >&2
    return 1
  fi

  echo "${found}"
}

## \fn find NAME
## \brief Find either a script or a library file.
find() {
  local found
  if found=$(find_script "$@" 2>/dev/null); then
    echo "${found}"
  elif found=$(find_lib "$@" 2>/dev/null); then
    echo "${found}"
  else
    echo "find: can't find $1" >&2
    return 1
  fi
}

## \fn shellm-include (filename)
## \brief Includes content of a library file in the current shell
## \param filename Name of library file to include
## \stderr Message if return code 1
## \return false (and exits if subshell) if no args or error while including contents, true otherwise
shellm-include() {
  local libdir array file
  if [ $# -eq 2 ]; then
    file="$1/$2"
  else
    file="$1"
  fi
  IFS=':' read -r -a array <<< "${LIBPATH}"
  for libdir in "${array[@]}"; do
    if [ -f "${libdir}/$1" ]; then
      # shellcheck disable=SC1090
      if ! . "${libdir}/$1"; then
        echo "shellm-include: error while including $1 (from $0)" >&2
        return 1
      fi
      return 0
    fi
  done
  echo "shellm-include: no such file: $1 (from $0)" >&2
  return 1
}

shellm-exclude() {
  local current_lib
  local include includes lib_header def defined

  # TODO: use find lib instead
  if [ -f "$1" ]; then
    current_lib="$1"
  elif [ -f "${SHELLM_USR}/lib/$1" ]; then
    current_lib="${SHELLM_USR}/lib/$1"
  elif [ -f "${SHELLM_ROOT}/lib/$1" ]; then
    current_lib="${SHELLM_ROOT}/lib/$1"
  else
    echo "shellm: exclude: no such file: $1 (from $0)"
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

## \fn shellm-ndef (varname)
## \brief Tests if a variable is set (non-empty)
## \param varname Variable name
## \return true if empty (unset), false otherwise
shellm-ndef() {
  # shellcheck disable=SC2086
  if [ $# -eq 1 ]; then
    declare -n _ref=$1
    if [ -z "${_ref+x}" ]; then
      return 0
    fi
    return 1
  else
    echo "shellm-ndef: usage: shellm-ndef <VARNAME>" >&2
    _shellm_die 1
  fi
}

export -f shellm
export -f shellm-load
export -f shellm-define
export -f shellm-ndef
export -f shellm-include

# Setup variables --------------------------------------------------------------
LOCAL_SHELLM_ROOT="${SHELLM_ROOT:-$1}"

if [ ! -n "${LOCAL_SHELLM_ROOT}" ]; then
  if [ -d "${HOME}/.shellm" ]; then
    export SHELLM_ROOT="${HOME}/.shellm"
  else
    echo "shellm: can't find myself (I'm serious.)" >&2
    echo "        Please tell me my location by either passing it as an argument to init.sh," >&2
    echo "        or set the SHELLM_ROOT variable before sourcing me." >&2
    echo "        You can also move me or symlink me as ${HOME}/.shellm" >&2
    return 1
  fi
else
  if [ -d "${LOCAL_SHELLM_ROOT}" ] || [ -L "${LOCAL_SHELLM_ROOT}" ]; then
    export SHELLM_ROOT="${LOCAL_SHELLM_ROOT}"
  else
    echo "shellm: no such directory: ${LOCAL_SHELLM_ROOT}" >&2
    return 1
  fi
fi

if ! echo "${PATH}" | grep -q "${SHELLM_ROOT}/bin"; then
  export PATH="${SHELLM_ROOT}/bin:${PATH}"
fi

export MANPATH="${SHELLM_ROOT}/man:"
export LIBPATH="/usr/local/lib/shellm:${SHELLM_ROOT}/lib"

unset LOCAL_SHELLM_ROOT

# Core libraries ---------------------------------------------------------------
#shellm-include "core/loadtime.sh"
#loadtime_init
shellm-include "core/shellman.sh"
#loadtime_finish

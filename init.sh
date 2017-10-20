# shellcheck disable=SC2148

_realpath() {
  local LOCATION
  LOCATION="$(readlink -e "$1")"
  while [ -L "${LOCATION}" ]; do
    LOCATION="$(readlink -e "${LOCATION}")"
  done
  echo "${LOCATION}"
}

_shellm_init() {
  local LOCAL_SHELLM_ROOT="${SHELLM_ROOT:-$1}"

  if [ ! -n "${LOCAL_SHELLM_ROOT}" ]; then
    if [ -d "${HOME}/.shellm" ]; then
      export SHELLM_ROOT="${HOME}/.shellm"
    else
      echo "shellm: can't find myself (I'm serious.)" >&2
      echo "        Please tell me my location by either passing it as an argument to init.sh," >&2
      echo "        or set the SHELLM_ROOT variable before sourcing me." >&2
      echo "        You can also move me or symlink me as ${HOME}/.shellm" >&2
      unset -f _shellm_init
      return 1
    fi
  else
    if [ -d "${LOCAL_SHELLM_ROOT}" ] || [ -L "${LOCAL_SHELLM_ROOT}" ]; then
      export SHELLM_ROOT="${LOCAL_SHELLM_ROOT}"
    else
      echo "shellm: no such directory: ${LOCAL_SHELLM_ROOT}" >&2
      unset -f _shellm_init
      return 1
    fi
  fi

  # Path variables
  if ! echo "${PATH}" | grep -q "${SHELLM_ROOT}/bin"; then
    export PATH="${SHELLM_ROOT}/bin:${PATH}"
  fi

  export MANPATH="${SHELLM_ROOT}/man:"
  export LIBPATH="${SHELLM_ROOT}/lib"

  shellm() {
    local cmd="$1"
    shift

    if ! command -v "shellm-${cmd}" >/dev/null; then
      echo "shellm: command ${cmd} does not exist; try 'shellm help' to list shellm commands" >&2
      return 1
    fi

    # shellcheck disable=SC2086
    shellm-${cmd} "$@"
  }

  shellm-load() {
    if [ $# -gt 1 ]; then
      echo "shellm: load: too many arguments" >&2
      return 1
    elif [ $# -eq 1 ]; then
      if [ -f "$1" ]; then
        SHELLM_PROFILE="$(_realpath "$1")"
      else
        echo "shellm: load: no such file: $1 (from argument 1)"
      fi
    elif [ -n "${SHELLM_PROFILE}" ]; then
      if [ -f "${SHELLM_PROFILE}" ]; then
        SHELLM_PROFILE="$(_realpath "${SHELLM_PROFILE}")"
      else
        echo "shellm: load: no such file: ${SHELLM_PROFILE} (from SHELLM_PROFILE variable)"
      fi
    elif [ -f "${HOME}/.shellm-profile" ]; then
      SHELLM_PROFILE="$(_realpath "${HOME}/.shellm-profile")"
    else
      echo "shellm: load: no profile loaded, try 'shellm help load' to see how profiles are loaded" >&2
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

  shellm-init() {
    local d dir
    if [ $# -eq 0 ]; then
      dir="${PWD}"
    else
      dir="$1"
      if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}" || return 1
      fi
    fi
    cp -ir "${SHELLM_ROOT}/initbase"/* "${dir}"
    for d in bin lib/env man/man1 man/man3; do
      mkdir -p "${dir}/$d"
    done
    shellm-load "${dir}/profile"
  }

  # Inclusion system
  # shellcheck source=lib/core/include.sh
  . "${SHELLM_ROOT}/lib/core/include.sh"

  # Load time measuring library
  include "core/loadtime.sh"
  # FIXME: why u no work??
  loadtime_init

  # Core libraries
  include "core/shellman.sh"

  loadtime_finish
  unset -f _shellm_init

  export -f shellm shellm-init shellm-load
}

_shellm_init "$@"

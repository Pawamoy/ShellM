# shellcheck disable=SC2148

_shellm_init() {
  local LOCAL_SHELLM_ROOT="${SHELLM_ROOT:-$1}"

  if [ ! -n "${LOCAL_SHELLM_ROOT}" ]; then
    if [ -d "${HOME}/.shellm" ]; then
      export SHELLM_ROOT="${HOME}/.shellm"
    else
      echo "shellm: did you forget to specify shellm's location with SHELLM_ROOT variable?" >&2
      unset -f _shellm_init
      return 1
    fi
  else
    if [ -d "${LOCAL_SHELLM_ROOT}" ]; then
      export SHELLM_ROOT="${LOCAL_SHELLM_ROOT}"
    else
      echo "shellm: no such directory: ${LOCAL_SHELLM_ROOT}" >&2
      unset -f _shellm_init
      return 1
    fi
  fi

  # Path variables
  if ! echo "${PATH}" | grep -q "${SHELLM_ROOT}"; then
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

  _shellm_resolve_link() {
    local SCRIPT_LOCATION
    while [ -L "${SCRIPT_LOCATION}" ]; do
      SCRIPT_LOCATION="$(readlink -e "${SCRIPT_LOCATION}")"
    done
    echo "${SCRIPT_LOCATION}"
  }

  shellm-load() {
    if [ $# -gt 1 ]; then
      echo "shellm: load: too many arguments" >&2
      return 1
    elif [ $# -eq 1 ]; then
      if [ -f "$1" ]; then
        SHELLM_PROFILE="$(_shellm_resolve_link "$1")"
      else
        echo "error"
      fi
    elif [ -n "${SHELLM_PROFILE}" ]; then
      if [ -f "${SHELLM_PROFILE}" ]; then
        SHELLM_PROFILE="$(_shellm_resolve_link "${SHELLM_PROFILE}")"
      else
        echo "error"
      fi
    elif [ -f "${HOME}/.shellm-profile" ]; then
      SHELLM_PROFILE="$(_shellm_resolve_link "${HOME}/.shellm-profile")"
    else
      echo "shellm: load: no profile loaded, try 'shellm help load' to see how profiles are loaded" >&2
      return 1
    fi

    SHELLM_USR="$(dirname "${SHELLM_PROFILE}")"
    export SHELLM_PROFILE SHELLM_USR
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
    shellm load "${dir}/shellmrc"
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
}

_shellm_init "$@"

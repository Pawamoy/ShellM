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

  shellm-load() {
    local profile
    if [ $# -gt 0 ]; then
      for profile in "$@"; do
        if [ -f "${profile}" ]; then
          # shellcheck disable=SC1090
          . "${profile}"
        fi
      done
    elif [ -n "${SHELLM_PROFILE}" ]; then
      # shellcheck disable=SC1090
      . "${SHELLM_PROFILE}"
    elif [ -f "${HOME}/.shellm-profile" ]; then
      # shellcheck disable=SC1090
      . "${HOME}/.shellm-profile"
    else
      echo "shellm: load: no profile loaded, try 'shellm help load' to see how profiles are loaded" >&2
      return 1
    fi
  }

  shellm-init() {
    local dir item
    if [ $# -eq 0 ]; then
      dir="${PWD}"
    else
      dir="$1"
      if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}" || return 1
      fi
    fi
    cp -irv "${SHELLM_ROOT}/usr-template"/* "${dir}"
    export SHELLM_PROFILE="${dir}/shellmrc"
    shellm load "${SHELLM_PROFILE}"
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

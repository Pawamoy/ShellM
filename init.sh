_shellm_init() {
  local SHELLM_ROOT="${SHELLM_ROOT:-$1}"

  if [ ! -n "${SHELLM_ROOT}" ]; then
    echo "shellm: did you forget to specify shellm's location with SHELLM_ROOT variable?" >&2
    unset -f _shellm_init
    return 1
  fi

  # Path variables
  if ! echo "${PATH}" | grep -q "${SHELLM_ROOT}"; then
    export PATH="${SHELLM_ROOT}/bin:${PATH}"
  fi

  MANPATH="${SHELLM_ROOT}/man:"
  export LIBPATH="${SHELLM_ROOT}/lib"

  shellm() {
    local cmd="$1"
    shift

    if ! command -v "shellm-${cmd}" >/dev/null; then
      echo "shellm: command ${cmd} does not exist; try 'shellm help' to list shellm commands" >&2
      return 1
    fi

    # Not needed since we always call the command the same way
    # case $(type -t "shellm-${cmd}") in
    #   alias|function|file) shellm-${cmd} "$@" ;;
    #   builtin|keyword) echo "shellm: this should never have happened O_o" >&2; return 1 ;;
    # esac
    shellm-${cmd} "$@"
  }

  shellm-load() {
    local profile
    if [ $# -gt 0 ]; then
      for profile in "$@"; do
        if [ -f "${profile}" ]; then
          . "${profile}"
        fi
      done
    elif [ -n "${SHELLM_PROFILE}" ]; then
      . "${SHELLM_PROFILE}"
    elif [ -f "${HOME}/.shellmrc" ]; then
      . "${HOME}/.shellmrc"
    else
      echo "shellm: load: no profile loaded, try 'shellm help load' to see how profiles are loaded" >&2
      return 1
    fi
  }

  # Inclusion system
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

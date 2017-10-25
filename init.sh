# shellcheck disable=SC2148

# Shellm functions -------------------------------------------------------------

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

shellm-load() {
  if [ $# -gt 1 ]; then
    echo "shellm: load: too many arguments" >&2
    return 1
  elif [ $# -eq 1 ]; then
    if [ -f "$1" ]; then
      SHELLM_PROFILE="$(realpath "$1")"
    else
      echo "shellm: load: no such file: $1 (from argument 1)"
    fi
  elif [ -n "${SHELLM_PROFILE}" ]; then
    if [ -f "${SHELLM_PROFILE}" ]; then
      SHELLM_PROFILE="$(realpath "${SHELLM_PROFILE}")"
    else
      echo "shellm: load: no such file: ${SHELLM_PROFILE} (from SHELLM_PROFILE variable)"
    fi
  elif [ -f "${HOME}/.shellm-profile" ]; then
    SHELLM_PROFILE="$(realpath "${HOME}/.shellm-profile")"
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

# TODO: write a shellm-cd command?

export -f shellm shellm-load

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
export LIBPATH="${SHELLM_ROOT}/lib"

unset LOCAL_SHELLM_ROOT

# Inclusion system -------------------------------------------------------------

# shellcheck source=lib/core/include.sh
. "${SHELLM_ROOT}/lib/core/include.sh"

# Load time measuring library
include "core/loadtime.sh"
loadtime_init

# Core libraries
include "core/shellman.sh"

loadtime_finish

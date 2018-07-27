# shellcheck disable=SC2148
# Shellm functions -------------------------------------------------------------
## TODO: add docs
shellm() {
  local cmd="$1"

  if command -v "shellm-${cmd}" &>/dev/null; then
    shift
    # shellcheck disable=SC2086
    shellm-${cmd} "$@"
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

# TODO: move elsewhere
_shellm_die() {
  case "${WINDOWID}" in
    [0-9]*) [ ${SHLVL} -gt 2 ] && exit $1 || return $1 ;;
    "") [ ${SHLVL} -gt 1 ] && exit $1 || return $1 ;;
  esac
}

_shellm_lib_not_included() {
  local i
  for i in ${SHELLM_INCLUDES[@]}; do
    [ "$1" = "$i" ] && return 1
  done
  return 0
}
export -f _shellm_lib_not_included

_shellm_include_lib() {
  SHELLM_INCLUDES+=("$1")
}
export -f _shellm_include_lib

_shellm_libstack_push() {
  __SHELLM_LIBSTACK+=("$1")
}
export -f _shellm_libstack_push

_shellm_libstack_pop() {
  unset __SHELLM_LIBSTACK[-1]
}
export -f _shellm_libstack_pop

## \fn shellm-include (filename)
## \brief Includes content of a library file in the current shell
## \param filename Name of library file to include
## \stderr Message if return code 1
## \return false (and exits if subshell) if no args or error while including contents, true otherwise
shellm-include() {
  local arg lib status

  # compatibility with basher
  if [ $# -eq 2 ]; then
    arg="$1/$2"
  else
    arg="$1"
  fi

  if lib="$(shellm-find-lib "${arg}")"; then
    if _shellm_lib_not_included "${lib}"; then
      _shellm_include_lib "${lib}"

      _shellm_libstack_push "${lib}"
      # shellcheck disable=SC1090
      . "${lib}"
      status=$?
      _shellm_libstack_pop

      if [ ${status} -ne 0 ]; then
        echo "shellm-include: error while including ${lib}" >&2
        echo "  command: $0" >&2
        echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
        return 1
      fi
    fi
  else
    echo "shellm-include: no such file in LIBPATH: ${arg}" >&2
    echo "  command: $0" >&2
    echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
    return 1
  fi
}
export -f shellm-include


# Setup variables --------------------------------------------------------------
declare -a __SHELLM_LIBSTACK
declare -a SHELLM_INCLUDES

if [ -d "/usr/local/packages" ]; then
  LIBPATH="/usr/local/packages:${LIBPATH}"
fi

if [ -d "${BASHER_PREFIX}" ]; then
  LIBPATH="${BASHER_PREFIX}/packages:${LIBPATH}"
elif [ -d "${HOME}/.basher/cellar/packages" ]; then
  LIBPATH="${HOME}/.basher/cellar/packages:${LIBPATH}"
fi

export LIBPATH

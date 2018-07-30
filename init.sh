# shellcheck disable=SC2148

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

## \fn find-lib <NAME>
## \brief Find a library file.
__shellm_locate() {
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
export -f __shellm_locate

__shellm_has_source() {
  local i
  for i in "${SHELLM_SOURCES[@]}"; do
    [ "$1" = "$i" ] && return 0
  done
  return 1
}
export -f __shellm_has_source

__shellm_add_source() {
  SHELLM_SOURCES+=("$1")
}
export -f __shellm_add_source

__shellm_libstack_push() {
  __SHELLM_LIBSTACK+=("$1")
}
export -f __shellm_libstack_push

__shellm_libstack_pop() {
  unset "__SHELLM_LIBSTACK[-1]"
}
export -f __shellm_libstack_pop

## \fn shellm-source (filename)
## \brief Includes content of a library file in the current shell
## \param filename Name of library file to include
## \stderr Message if return code 1
## \return false (and exits if subshell) if no args or error while including contents, true otherwise
shellm-source() {
  local arg lib status

  # compatibility with basher
  if [ $# -eq 2 ]; then
    arg="$1/$2"
  else
    arg="$1"
  fi

  if lib="$(__shellm_locate "${arg}")"; then

    if ! __shellm_has_source "${lib}"; then

      __shellm_add_source "${lib}"
      __shellm_libstack_push "${lib}"

      # shellcheck disable=SC1090
      . "${lib}"
      status=$?

      __shellm_libstack_pop

      if [ ${status} -ne 0 ]; then
        echo "shellm-source: error while including ${lib}" >&2
        echo "  command: $0" >&2
        echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
        return 1
      fi

    fi

  else

    echo "shellm-source: no such file in LIBPATH: ${arg}" >&2
    echo "  command: $0" >&2
    echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
    return 1

  fi
}
export -f shellm-source


declare -a __SHELLM_LIBSTACK
declare -a SHELLM_SOURCES

if [ -d "${BASHER_PREFIX}" ]; then
  LIBPATH="${BASHER_PREFIX}/packages:${LIBPATH}"
elif [ -d "${HOME}/.basher/cellar/packages" ]; then
  LIBPATH="${HOME}/.basher/cellar/packages:${LIBPATH}"
fi

export LIBPATH

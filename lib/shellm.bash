# shellcheck disable=SC2148

## \function shellm <COMMAND> [ARGS]
## \function-brief Execute a shellm command, be it a function or a script.
## \function-argument COMMAND The name of an existing shellm command.
## \function-return ? The return code of the invoked command.
## \function-return 1 Unkown command.
## \function-stderr "Unkown command" if the command is not found.
shellm() {
  local command

  command="${1:-}"
  (( $# > 0 )) && shift
  case "${command}" in
    locate|source|trace)
      # shellcheck disable=SC2086
      __shellm_${command} "$@"
    ;;
    *) command shellm "${command}" "$@" ;;
  esac
}

## \function shellm-locate <FILEPATH>
## \function-brief Locate a library file in LIBPATH.
## \function-argument FILEPATH The relative file path.
## \function-return 0 File found.
## \function-return 1 File not found.
## \function-stdout The absolute path to the file found.
__shellm_locate() {
  local libdir
  IFS=':' read -r -a array <<< "${LIBPATH}"
  for libdir in "${array[@]}"; do
    if [ -e "${libdir}/$1" ]; then
      echo "${libdir}/$1"
      return 0
    fi
  done
  return 1
}

## \function __shellm_has_source <LIBFILE>
## \function-brief Check if LIBFILE is already in shellm sources.
## \function-argument LIBFILE The file absolute path.
## \function-return 0 Source is loaded.
## \function-return 1 Source is not loaded.
__shellm_has_source() {
  local i
  for i in "${SHELLM_SOURCES[@]}"; do
    [ "$1" = "$i" ] && return 0
  done
  return 1
}

## \function __shellm_add_source <LIBFILE>
## \function-brief Append source LIBFILE to shellm sources.
## \function-argument LIBFILE The file absolute path.
__shellm_add_source() {
  SHELLM_SOURCES+=("$1")
}

## \function __shellm_libstack_push <LIBFILE>
## \function-brief Append source LIBFILE to the souce stack.
## \function-argument LIBFILE The file absolute path.
__shellm_libstack_push() {
  __SHELLM_LIBSTACK+=("$1")
}

## \function __shellm_libstack_pop
## \function-brief Remove the last item of the source stack.
## \function-argument NAME The source name, e.g. `shellm/home/lib/home.sh`.
__shellm_libstack_pop() {
  unset "__SHELLM_LIBSTACK[-1]"
}

## \function __shellm_source <NAME> <ABS_PATH>
## \function-brief Load source if not loaded, measure load time, warn when errors.
## This function first sets the time delta sum to 0.
## Then it checks if the given source is already loaded or not.
## If not, it adds it in the sources list and stack, then start the timer.
## It sources it, end the timer, and remove it from the stack.
## If something went wrong while loading it, it echoes an error with references:
## original script, source file, current stack.
## \function-argument NAME The source name, e.g. `shellm/home/lib/home.sh`.
## \function-argument ABS_PATH The library file absolute path.
## \function-stderr Warning if error when sourcing file.
## \function-return 0 Everything OK.
## \function-return 1 Error when sourcing file.
__shellm_psource() {
  local status lib

  __shellm_hook_source_start "$@"

  if ! __shellm_has_source "$2"; then

    __shellm_add_source "$2"
    __shellm_libstack_push "$2"

    __shellm_hook_source_before_source "$@"

    # shellcheck disable=SC1090
    . "$2"
    status=$?

    __shellm_hook_source_after_source "${status}" "$@"

    __shellm_libstack_pop

    if [ ${status} -ne 0 ]; then
      echo "shellm-source: error while including '$2'" >&2
      return 1
    fi

  fi

  __shellm_hook_source_end "$@"
}

__shellm_hook_run() {
  local hook
  declare -n _hooks="$1"
  shift
  for hook in "${_hooks[@]}"; do
    ${hook} "$@"
  done
}

__shellm_hook_source_start() {
  __shellm_hook_run SHELLM_HOOKS_SOURCE_START "$@"
}

__shellm_hook_source_end() {
  __shellm_hook_run SHELLM_HOOKS_SOURCE_END "$@"
}

__shellm_hook_source_before_source() {
  __shellm_hook_run SHELLM_HOOKS_SOURCE_BEFORE_SOURCE "$@"
}

__shellm_hook_source_after_source() {
  __shellm_hook_run SHELLM_HOOKS_SOURCE_AFTER_SOURCE "$@"
}

## \function shellm-source <NAME>
## \function-brief Locate a source or package, and source it in the current shell process.
## If NAME is a package, searches for every file in a `lib` directory
## and sources each one of them.
## \function-argument NAME The source or package name, e.g. `shellm/home`.
## \function-stderr Warning when package or source is not found.
## \function-return 1 Source or package not found.
__shellm_source() {
  local arg lib sublib status

  # compatibility with basher
  if [ $# -eq 2 ]; then
    arg="$1/$2"
  else
    arg="$1"
  fi

  if lib="$(__shellm_locate "${arg}")"; then

    if [ -d "${lib}" ]; then
      # shellcheck disable=SC2164
      for sublib in $(cd "${lib}"; find lib -maxdepth 1 -type f 2>/dev/null); do
        __shellm_psource "${arg}/${sublib}" "${lib}/${sublib}"
      done
    elif [ -f "${lib}" ]; then
      __shellm_psource "${arg}" "${lib}"
    fi

  else
    echo "shellm: source: no such file in LIBPATH: '${arg}'" >&2
    return 1

  fi
}

## \env __SHELLM_LIBSTACK The current stack of sources being loaded.
declare -a __SHELLM_LIBSTACK

## \env SHELLM_SOURCES The list of sources already loaded in the current shell process.
declare -a SHELLM_SOURCES

# TODO: document these
# shellcheck disable=SC2034
declare -a SHELLM_HOOKS_SOURCE_START
# shellcheck disable=SC2034
declare -a SHELLM_HOOKS_SOURCE_END
# shellcheck disable=SC2034
declare -a SHELLM_HOOKS_SOURCE_BEFORE_SOURCE
# shellcheck disable=SC2034
declare -a SHELLM_HOOKS_SOURCE_AFTER_SOURCE

## \env LIBPATH The colon-separated list of directories
## in which to search for library files or packages.
if [ -d "${BASHER_PACKAGES_PATH}" ]; then
  if ! echo "${LIBPATH}" | grep -q "${BASHER_PACKAGES_PATH}"; then
    LIBPATH="${LIBPATH}:${BASHER_PACKAGES_PATH}"
  fi
elif [ -d "${BASHER_PREFIX}/packages" ]; then
  if ! echo "${LIBPATH}" | grep -q "${BASHER_PREFIX}/packages"; then
    LIBPATH="${LIBPATH}:${BASHER_PREFIX}/packages"
  fi
fi

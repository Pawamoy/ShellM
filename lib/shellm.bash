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
    locate|source)
      # shellcheck disable=SC2086
      __shellm_${command} "$@"
    ;;
    *)
      command shellm "${command}" "$@"
    ;;
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
  local src
  local has_src
  local status
  local lib
  local libpath

  libpath="$1"
  shift

  __shellm_hook_run source_start "${libpath}" "$@"

  has_src=0
  if (( force == 0 )); then
    for src in "${SHELLM_SOURCES[@]}"; do
      if [ "${libpath}" = "${src}" ]; then
        has_src=1
        break
      fi
    done
  fi

  if (( has_src == 0 )); then

    (( force == 0 )) && SHELLM_SOURCES+=("${libpath}")
    __SHELLM_LIBSTACK+=("${libpath}")

    __shellm_hook_run source_before_source "${libpath}" "$@"

    # shellcheck disable=SC1090
    source "${libpath}" "$@"
    status=$?

    __shellm_hook_run source_after_source "${status}" "${libpath}" "$@"

    # pop last array item
    unset '__SHELLM_LIBSTACK[-1]'

    if [ ${status} -ne 0 ]; then
      >&2 echo "shellm: source: error while sourcing '${libpath}'"
    fi

  fi

  __shellm_hook_run source_end "${libpath}" "$@"

  return ${status}
}

__shellm_hook_run() {
  local hook
  declare -n _hooks="SHELLM_HOOKS_${1^^}"
  shift
  for hook in "${_hooks[@]}"; do
    ${hook} "$@"
  done
}

## \function __shellm_source <NAME>
## \function-brief Locate a source or package, and source it in the current shell process.
## If NAME is a package, searches for every file in a `lib` directory
## and sources each one of them.
## \function-argument NAME The source or package name, e.g. `shellm/home`.
## \function-stderr Warning when package or source is not found.
## \function-return 1 Source or package not found.
# TODO: add -f option to force re-sourcing
__shellm_source() {
  local arg
  local lib
  local sublib
  local sublibs
  local status
  local options
  local force=0

  options="$(getopt -n shellm-source -o "fh" -l "force,help" -- "$@")"
  command eval set -- "${options}"
  while (( $# != 0 )); do
    case $1 in
      -f|--force) force=1 ;;
      -h|--help)
        shellm help source
        return 0
      ;;
      --) shift; break ;;
    esac
    shift
  done

  if (( $# == 0 )); then
    >&2 echo "usage: shellm source [-hf] <LIBRARY>"
    return 1
  fi

  arg=$1
  shift

  if lib="$(__shellm_locate "${arg}")"; then
    if [ -d "${lib}" ]; then
      # shellcheck disable=SC2164
      if [ -f "${lib}/package.sh" ]; then
        # shellcheck disable=SC1090
        mapfile -t sublibs <<<"$(source "${lib}/package.sh"; tr : '\n' <<<"${SHELLM_LIBS}")"
        if [ ${#sublibs[@]} -eq 0 ]; then
          >&2 echo "shellm: source: no libraries specified in SHELLM_LIBS array in '${lib}/package.sh'"
          return 1
        else
          for sublib in "${sublibs[@]}"; do
            __shellm_psource "${lib}/${sublib}" "$@"
          done
        fi
      else
        >&2 echo "shellm: source: cannot source a directory"
      fi
    elif [ -f "${lib}" ]; then
      __shellm_psource "${lib}" "$@"
    fi
  else
    >&2 echo "shellm: source: no such file in LIBPATH: '${arg}'"
    return 1
  fi
}

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
if ! echo "${LIBPATH}" | grep -q "${BASHER_PACKAGES_PATH}"; then
  LIBPATH="${LIBPATH}:${BASHER_PACKAGES_PATH}"
fi

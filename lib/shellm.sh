# shellcheck disable=SC2148

## \function shellm <COMMAND> [ARGS]
## \function-brief Execute a shellm command, be it a function or a script.
## \function-argument COMMAND The name of an existing shellm command.
## \function-return ? The return code of the invoked command.
## \function-return 1 Unkown command.
## \function-stderr "Unkown command" if the command is not found.
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

## \function __shellm_locate <FILEPATH>
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

## \env SHELLM_TIME
## If set, shellm will measure the loading time for each library
## file sourced in the current process. You will then be able to
## print this information with the command `shellm-print-loadtime`.
if [ ! -z ${SHELLM_TIME+x} ]; then

  ## \function __shellm_time_set_delta
  ## \function-brief Set the time delta sum variable to 0.
  __shellm_time_set_delta() {
    if [ ${#__SHELLM_LIBSTACK[@]} -eq 0 ]; then
      __SHELLM_DELTA_SUM=0
    fi
  }

  ## \function __shellm_time_unset_delta
  ## \function-brief Unset the time delta sum variable.
  __shellm_time_unset_delta() {
    if [ ${#__SHELLM_LIBSTACK[@]} -eq 0 ]; then
      unset __SHELLM_DELTA_SUM
    fi
  }

  ## \function __shellm_time_now
  ## \function-brief Return a timestamp (seconds since Epoch plus nanoseconds).
  ## \function-stdout The date and time in seconds since Epoch.
  __shellm_time_now() {
    date +%s.%N
  }

  ## \function __shellm_time_start
  ## \function-brief Start the timer (store `now` in parent local start variable).
  __shellm_time_start() {
    start=$(__shellm_time_now)
  }

  ## \function __shellm_time_end <NAME>
  ## \function-brief End the timer and update the time delta sum.
  ## Write-append the time delta for the given source
  ## in this process' data file.
  ## \function-argument NAME The source name, e.g. `shellm/home/lib/home.sh`.
  __shellm_time_end() {
    local delta delta_sum
    delta_sum=$(bc -l <<<"$(__shellm_time_now) - ${start}")
    delta=$(bc -l <<<"${delta_sum} - ${__SHELLM_DELTA_SUM}")
    __SHELLM_DELTA_SUM=${delta_sum}
    [ "${delta:0:1}" = "." ] && delta="0${delta}"
    ## \file /tmp/shellm-time.PID
    ## Data file used to store loading time per source for given process.
    echo "$1:${delta}" >> "/tmp/shellm-time.$$"
  }

else

  __shellm_time_set_delta() { :; }
  __shellm_time_unset_delta() { :; }
  __shellm_time_now() { :; }
  __shellm_time_start() { :; }
  __shellm_time_end() { :; }

fi

## \function shellm-print-loadtime [PID]
## \function-brief Pretty-print the loading time for each source for a given shell process.
## \function-argument PID The PID of a shell process (default to $$).
## \function-stdout Loading time for each source and total time.
## \function-seealso The SHELLM_TIME environment variable.
## \function-return 1 Data file for the given PID does not exist.
shellm-print-loadtime() {
  local pid line mfile file seconds total longest

  if [ $# -gt 0 ]; then
    pid="$1"
  else
    pid=$$
  fi

  mfile="/tmp/shellm-time.${pid}"

  if [ ! -f "${mfile}" ]; then
    echo "shellm-print-loadtime: no time data for process ${pid}" >&2
    echo "Make sure SHELLM_TIME variable is set to activate loading time measurements."
    return 1
  fi

  longest=$(cut -d: -f-1 "${mfile}" | wc -L)
  echo "Measured load time for shell process ${pid}"
  echo
  sort -rt: -k2 "${mfile}" | while read -r line; do
    file="${line%:*}"
    seconds="${line##*:}"
    # shellcheck disable=SC1117
    printf "%${longest}s: %ss\n" "${file}" "${seconds:0:-6}"
  done
  echo
  total="$(cut -d: -f2 "${mfile}" | awk '{s+=$1} END {print s}')"
  total=${total:0:-2}
  echo "Total load time: ${total} seconds"
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
__shellm_source() {
  local status

  __shellm_time_set_delta

  if ! __shellm_has_source "$2"; then

    __shellm_add_source "$2"
    __shellm_libstack_push "$2"

    __shellm_time_start

    # shellcheck disable=SC1090
    . "$2"
    status=$?

    __shellm_time_end "$1"

    __shellm_libstack_pop

    if [ ${status} -ne 0 ]; then
      echo "shellm-source: error while including $2" >&2
      echo "  command: $0" >&2
      echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
      return 1
    fi

  fi

  __shellm_time_unset_delta
}

## \function shellm-source <NAME>
## \function-brief Locate a source or package, and source it in the current shell process.
## If NAME is a package, searches for every file in a `lib` directory
## and sources each one of them.
## \function-argument NAME The source or package name, e.g. `shellm/home`.
## \function-stderr Warning when package or source is not found.
## \function-return 1 Source or package not found.
shellm-source() {
  local arg lib sublib status start

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
        __shellm_source "${arg}/${sublib}" "${lib}/${sublib}"
      done
    elif [ -f "${lib}" ]; then
      __shellm_source "${arg}" "${lib}"
    fi

  else

    echo "shellm-source: no such file in LIBPATH: ${arg}" >&2
    echo "  command: $0" >&2
    echo "  library stack: ${__SHELLM_LIBSTACK[*]}" >&2
    return 1

  fi
}

## \env __SHELLM_LIBSTACK The current stack of sources being loaded.
declare -a __SHELLM_LIBSTACK

## \env SHELLM_SOURCES The list of sources already loaded in the current shell process.
declare -a SHELLM_SOURCES

## \env LIBPATH The colon-separated list of directories
## in which to search for library files or packages.
if [ -d "${BASHER_PREFIX}/packages" ]; then
  if ! echo "${LIBPATH}" | grep -q "${BASHER_PREFIX}/packages"; then
    LIBPATH="${BASHER_PREFIX}/packages:${LIBPATH}"
  fi
elif [ -d "${HOME}/.basher/cellar/packages" ]; then
  if ! echo "${LIBPATH}" | grep -q "${HOME}/.basher/cellar/packages"; then
    LIBPATH="${HOME}/.basher/cellar/packages:${LIBPATH}"
  fi
fi

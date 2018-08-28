# shellcheck disable=SC2148

# TODO: add docs
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

## \fn find-lib <NAME>
## \brief Find a library file.
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

__shellm_has_source() {
  local i
  for i in "${SHELLM_SOURCES[@]}"; do
    [ "$1" = "$i" ] && return 0
  done
  return 1
}

__shellm_add_source() {
  SHELLM_SOURCES+=("$1")
}

__shellm_libstack_push() {
  __SHELLM_LIBSTACK+=("$1")
}

__shellm_libstack_pop() {
  unset "__SHELLM_LIBSTACK[-1]"
}

if [ -n "${SHELLM_TIME}" ]; then
  
  __shellm_time_set_delta() {
    if [ ${#__SHELLM_LIBSTACK[@]} -eq 0 ]; then
      __SHELLM_DELTA_SUM=0
    fi
  }

  __shellm_time_unset_delta() {
    if [ ${#__SHELLM_LIBSTACK[@]} -eq 0 ]; then
      unset __SHELLM_DELTA_SUM
    fi
  }

  __shellm_time_now() {
    date +%s.%N
  }

  __shellm_time_start() {
    start=$(__shellm_time_now)
  }

  __shellm_time_end() {
    local delta delta_sum
    delta_sum=$(bc -l <<<"$(__shellm_time_now) - ${start}")
    delta=$(bc -l <<<"${delta_sum} - ${__SHELLM_DELTA_SUM}")
    __SHELLM_DELTA_SUM=${delta_sum}
    [ "${delta:0:1}" = "." ] && delta="0${delta}"
    echo "$1:${delta}" >> "/tmp/shellm-time.$$"
  }

else

  __shellm_time_set_delta() { :; }
  __shellm_time_unset_delta() { :; }
  __shellm_time_now() { :; }
  __shellm_time_start() { :; }
  __shellm_time_end() { :; }

fi

__shellm_time_print() {
  local pid line mfile file seconds total longest
  if [ $# -gt 0 ]; then
    pid="$1"
  else
    pid=$$
  fi
  mfile="/tmp/shellm-time.${pid}"
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

## \fn shellm-source (filename)
## \brief Includes content of a library file in the current shell
## \param filename Name of library file to include
## \stderr Message if return code 1
## \return false (and exits if subshell) if no args or error while including contents, true otherwise
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


declare -a __SHELLM_LIBSTACK
declare -a SHELLM_SOURCES

if [ -d "${BASHER_PREFIX}/packages" ]; then
  if ! echo "${LIBPATH}" | grep -q "${BASHER_PREFIX}/packages"; then
    LIBPATH="${BASHER_PREFIX}/packages:${LIBPATH}"
  fi
elif [ -d "${HOME}/.basher/cellar/packages" ]; then
  if ! echo "${LIBPATH}" | grep -q "${HOME}/.basher/cellar/packages"; then
    LIBPATH="${HOME}/.basher/cellar/packages:${LIBPATH}"
  fi
fi

export LIBPATH

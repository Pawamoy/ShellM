if shellm ndef __CORE_LOADTIME_SH; then
shellm define __CORE_LOADTIME_SH "
  loadtime_init
  loadtime_measure
  loadtime_finish
  loadtime_print"

## \brief Functions to measure time to load libraries with include system.

# TODO: deprecated, rewrite the whole system (don't mess with shellm-include)

loadtime_init() {
  MEASURE_LOAD_TIME_FILE="/tmp/shellm-measured-load-time.$$"
  alias shellm-include='loadtime_measure'
}

loadtime_measure() {
  unalias shellm-include
  local start end diff
  start=$(date +%s.%N)
  shellm include "$1"
  end=$(date +%s.%N)
  diff=$(echo "${end} - ${start}" | bc -l)
  case ${diff} in
    .*) diff="0${diff}" ;;
  esac
  echo "$1:${diff}" >> "${MEASURE_LOAD_TIME_FILE}"
  alias include='loadtime_measure'
}

loadtime_finish() {
  unalias include
}

loadtime_print() {
  local pid line mfile file seconds total longest
  if [ $# -gt 0 ]; then
    pid="$1"
  else
    pid=$$
  fi
  mfile="/tmp/shellm-measured-load-time.${pid}"
  longest=$(cut -d: -f-1 "${mfile}" | wc -L)
  echo "Measured load time for shell process ${pid}"
  echo
  sort -rt: -k2 "${mfile}" | while read -r line; do
    file="${line%:*}"
    seconds="${line##*:}"
    printf "%${longest}s: %ss\n" "${file}" "${seconds:0:-6}"
  done
  echo
  total="$(cut -d: -f2 "${mfile}" | awk '{s+=$1} END {print s}')"
  total=${total:0:-2}
  echo "Total load time: ${total} seconds"
}

fi  # __CORE_LOADTIME_SH

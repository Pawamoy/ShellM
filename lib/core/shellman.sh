if ndef __CORE_SHELLMAN_SH; then
define __CORE_SHELLMAN_SH

shellman_re='^[[:space:]]*##[[:space:]]*[@\]'

usage() {
	echo "usage: $(shellman_get usage "${1:-$0}")"
}

shellman_get() {
  local re
  case "$1" in
    host)
      re='##[[:space:]]*[@\]host[[:space:]]'
      grep "$re" "$2"
    ;;
    # bug|caveat|copyright|desc|env|err|error|example|exit|file|history|in|license|note|option|out|synopsis) return 1 ;;
    *)
      re="${shellman_re}$1"'[[:space:]]'
      grep "$re" "$2" | expand | sed 's/'"$re"'*//'
    ;;
  esac
}

fi # __CORE_SHELLMAN_SH

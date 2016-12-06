if ndef __CORE_SHELLMAN_SH; then
define __CORE_SHELLMAN_SH "
  shellman_re
  usage
  shellm_get"

## \brief Wrapper for shellman.

shellman_re='^[[:space:]]*##[[:space:]]*[@\]'

usage() {
  echo "usage: $(shellman_get usage "${1:-$0}")"
  exit 0
}

shellman_get() {
  local re
  case "$1" in
    host)
      re='##[[:space:]]*[@\]host[[:space:]]'
      grep "$re" "$2"
    ;;
    *)
      re="${shellman_re}$1"'[[:space:]]'
      grep "$re" "$2" | expand | sed 's/'"$re"'*//'
      # shellcheck disable=SC2086
      return ${PIPESTATUS[0]}
    ;;
  esac
}

fi # __CORE_SHELLMAN_SH

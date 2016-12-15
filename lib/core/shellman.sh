if ndef __CORE_SHELLMAN_SH; then
define __CORE_SHELLMAN_SH "
  shellman_re
  usage
  shellm_get"

## \brief Wrapper for shellman.

shellman_re='^[[:space:]]*##[[:space:]]*[@\]'

usage() {
  local usages
  usages="$(shellman_get usage "${1:-$0}")"
  echo "usage: $(echo "${usages}" | head -n1)"
  echo "${usages}" | tail -n+2 | while read -r line; do
    echo "       ${line}"
  done
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

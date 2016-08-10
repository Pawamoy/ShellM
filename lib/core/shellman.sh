if ndef __CORE_SHELLMAN_SH; then
define __CORE_SHELLMAN_SH "
  shellman_re
  usage
  shellm_get
  shellman"

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

shellman() {
  local OUTPUT SCRIPT REDIRECT=false FORMAT='text'

  while [ $# -ne 0 ]; do
    case $1 in
      ## \option -m, --man
      ## Output MAN documentation on stdout.
      '-m'|'--man') FORMAT='man' ;;
      ## \option -s, --shellm
      ## Write MAN documentation in shellm/usr/man/man1/FILE.
      '-s'|'--shellm') FORMAT='man'; REDIRECT=true ;;
      ## \option -t, --text
      ## Output help text on stdout.
      '-t'|'--text') FORMAT='text' ;;
      ## \option -h, --help
      ## Print this help and exit.
      '-h'|'--help') shellman -t "$0"; return 0 ;;
      *)
        # shellcheck disable=SC2154
        if [ -f "$1" ]; then
          SCRIPT="$1"
        elif [ -f "${shellm}/usr/bin/$1" ]; then
          SCRIPT="${shellm}/usr/bin/$1"
        elif [ -f "${shellm}/bin/$1" ]; then
          SCRIPT="${shellm}/bin/$1"
        else
          local libdir array
          IFS=':' read -r -a array <<< "${LIBPATH}"
          for libdir in "${array[@]}"; do
            if [ -f "${libdir}/$1" ]; then
              SCRIPT="${libdir}/$1"
              break
            fi
          done
          if [ -z "${SCRIPT}" ]; then
            echo "shellman: $1: no such script in shellm bin" >&2
            return 1
          fi
        fi
      ;;
    esac
    shift
  done

  local shellman_py="${shellm}/bin/shellman/shellman.py"
  OUTPUT=$(SHELLMAN_FORMAT="$FORMAT" "${shellman_py}" "$SCRIPT")
  if ${REDIRECT}; then
    echo "$OUTPUT" > "$shellm/usr/man/man1/${SCRIPT##*/}.1"
  else
    echo "${OUTPUT}"
  fi
}

fi # __CORE_SHELLMAN_SH

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

shellman() {
  local OUTPUT SCRIPT REDIRECT=false FORMAT='text'

  while [ $# -ne 0 ]; do
    case $1 in
      ## \option -m, --man
      ## Output MAN documentation on stdout
      '-m'|'--man') FORMAT='man' ;;
      ## \option -s, --shellm
      ## Write MAN documentation in shellm/usr/man/man1/FILE
      '-s'|'--shellm') FORMAT='man'; REDIRECT=true ;;
      ## \option -t, --text
      ## Outputs help text on stdout
      '-t'|'--text') FORMAT='text' ;;
      ## \option -h, --help
      ## Print this help and exit
      '-h'|'--help') shellman -t "$0"; exit 0 ;;
      *) [ -f "$1" ] && SCRIPT="$1" ||
          die "shellman: $1: no such regular file" ;;
    esac
    shift
  done

  OUTPUT=$(SHELLMAN_FORMAT="$FORMAT" shellman.py "$SCRIPT")
  if ${REDIRECT}; then
    echo "$OUTPUT" > "$shellm/usr/man/man1/${SCRIPT##*/}.1"
  else
    echo "${OUTPUT}"
  fi
}

fi # __CORE_SHELLMAN_SH

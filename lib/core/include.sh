## \brief Include functions for scripts (ndef, define, include)

## \fn define (name, [value])
## \brief Defines an environment variable in the current shell
## \param name Variable name
## \param value Optional, variable content (default: 'def')
## \return false if no args or error while affectation, true otherwise
define() {
  [ $# -ge 1 ] && eval "$1=\"${2:-DEF}\"" || return 1;
}

## \fn filter_host (file, [host])
## \param file Path to file to filter
## \param host Optional, name of the host to filter, default to $HOSTNAME
## \echo Filtered file
filter_host() {
  { grep -nE '##.*[\@]host.*[ ,  ]'${2:-$HOSTNAME}'[ ,  ]?' "$1"
    grep -nv '##.*[\@]host' "$1"
  } | sort -g | cut -d':' -f2-
}

## \fn include (filename)
## \brief Includes content of a library file in the current shell
## \param filename Name of library file to include
## \echo Message on stderr if return code 1
## \return false (and exits if subshell) if no args or error while including contents, true otherwise
include() {
  local libdir array
  IFS=':' read -r -a array <<< "${LIBPATH}"
  for libdir in "${array[@]}"; do
    if [ -f "${libdir}/$1" ]; then
      . <(filter_host "${libdir}/$1") && break
      [ $# -ge 1 ] && echo "include: error while including $1 from $0" >&2;
      # FIXME: zsh, sh, dash, csh, tcsh, ksh, xonsh...
      [ "$0" != "bash" ] && exit 1 || return 1;
    fi
  done
}

## \fn ndef (varname)
## \brief Tests if a variable is set (non-empty)
## \param varname Variable name
## \return true if empty (unset), false otherwise
ndef() {
  [[ $# -ge 1 && -z "$(eval echo \$$1)" ]] || return 1;
}

export -f define
export -f filter_host
export -f include
export -f ndef

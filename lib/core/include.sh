## \brief Include functions for scripts (ndef, define, include)

## \fn define (name, [value])
## \brief Defines an environment variable in the current shell
## \param name Variable name
## \param value Optional, variable content (default: 'def')
## \return false if no args or error while affectation, true otherwise
define() {
  [ $# -ge 1 ] && eval "$1=\"${2:-DEF}\"" || return 1
}

## \fn include (filename)
## \brief Includes content of a library file in the current shell
## \param filename Name of library file to include
## \stderr Message if return code 1
## \return false (and exits if subshell) if no args or error while including contents, true otherwise
include() {
  local libdir array
  IFS=':' read -r -a array <<< "${LIBPATH}"
  for libdir in "${array[@]}"; do
    if [ -f "${libdir}/$1" ]; then
      # shellcheck disable=SC1090
      . "${libdir}/$1" && break
      [ $# -ge 1 ] && echo "shellm: include: error while including $1 from $0" >&2
      case "${WINDOWID}" in
        [0-9]*) [ ${SHLVL} -gt 2 ] && exit 1 || return 1 ;;
        "") [ ${SHLVL} -gt 1 ] && exit 1 || return 1 ;;
      esac
    fi
  done
}

## \fn ndef (varname)
## \brief Tests if a variable is set (non-empty)
## \param varname Variable name
## \return true if empty (unset), false otherwise
ndef() {
  # shellcheck disable=SC2086
  [[ $# -ge 1 && -z "${!1}" ]] || return 1
}

export -f define
export -f include
export -f ndef

## @file include.sh
## @brief Include functions for scripts (ndef, define, include)

## @fn int define (name, value)
## @brief Defines an environment variable in the current shell
## @param $1 Variable name
## @param [$2] Variable content (default: 'def')
## @return Code: 1 if no args or error while affectation, 0 otherwise
define() {
	[ $# -ge 1 ] && eval $1=${2:-def} || return 1;
}

## @fn bool ndef (varname)
## @brief Tests if a variable is set (non-empty)
## @param $1 Variable name
## @return true if empty (unset), false otherwise
ndef() {
	[[ $# -ge 1 && -z "$(eval echo \$$1)" ]] || return 1;
}

## @fn int include (filename)
## @brief Includes content of a library file in the current shell
## @param $1 Names of library files to include
## @return Code: 1 (and exits if subshell) if no args or error while including contents, 0 otherwise
## @return Echo: message on stderr if return code 1
include() {
  local libdir
	local libdirarray
	IFS=':' read -r -a libdirarray <<< "${LIBPATH}"
	for libdir in "${libdirarray[@]}"; do
  	if [ -f "${libdir}/$1" ]; then
      . "${libdir}/$1" && break
  		[ $# -ge 1 ] && echo "include: error while including $1 from $0" >&2;
      [ "$0" != "bash" ] && exit 1 || return 1;
    fi
  done
}

export -f define
export -f ndef
export -f include

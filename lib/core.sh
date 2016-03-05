## @file shellm core libraries
## @desc Core libraries contain the include function,

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
  local dir
	for libdir in ${LIBPATH//:/ }; do
  	if [ -f "$libdir/$1" ]; then
      . "$libdir/$1" && break
  		[ $# -ge 1 ] && echo "include: error while including $1 from $0" >&2;
      [ "$0" != "bash" ] && exit 1 || return 1;
    fi
  done
}

real_path() {
  local readlink=$(which readlink)
  local script_location=${BASH_SOURCE[0]}
  if [ -x "$readlink" ]; then
    while [ -L "$script_location" ]; do
      script_location=$("$readlink" -e "$script_location")
    done
  fi
  echo "$script_location"
}

init() {
  DATADIR="$shellm/usr/data/${BASH_SOURCE[0]##*/}"
  mkdir -p "$DATADIR" 2>/dev/null

}

export -f define
export -f ndef
export -f include

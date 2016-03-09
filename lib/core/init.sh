## @fn void init (void)
## @brief Initialize environment variables for shellm scripts
init() {
  DATADIR="${shellm}/usr/data/${BASH_SOURCE[0]##*/}"
  mkdir -p "${DATADIR}" 2>/dev/null

}

## @fn void check (file)
## @brief Check if packages/executables in file are installed,
## or in $0 if no file given (then ask to continue or not if some are missing)
## @param [$1] File to check (default $0)
## @return Echo: missing packages/executables, question if $0
check() {
	[ "$cgIgnoreCheck" = "yes" ] && return 0
	local s ret=true a=${1:-$0}
	for s in $(getPackages "$a"); do
		havePackage "$s" || { err "Package $s not found !"; false; }
		ret=$( ([ $? -eq 0 ] && $ret) && echo true || echo false)
	done
	for s in $(getDepends "$a"); do
		haveExec "$s" || { err "Executable $s not found !"; false; }
		ret=$( ([ $? -eq 0 ] && $ret) && echo true || echo false)
	done
	if [ -z "$1" ] && ! $ret; then
		err; err "Some required packages and/or executables were not found..."
		question "Would you like to continue anyway ? (unpredictable behavior) [yN]" || end 0
		line "-"
	fi
}

activate_check() {
	export cgIgnoreCheck=no
}

deactivate_check() {
	export cgIgnoreCheck=yes
}

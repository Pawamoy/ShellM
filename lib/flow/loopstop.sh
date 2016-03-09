if ndef __LOOPSTOP_SH; then
define _LOOPSTOP_SH

## @file loopstop.sh
## @brief Provide a loop control function

## @fn void loopstop (script, conditions, ..., control)
## @brief Without script, print currently used scripts.
## Without conditions, print currently used conditions for script.
## Without control, check if conditions are valid (0) or not (1).
## @param [$1] Unique (script) name for storing conditions.
## @param [$2-] Conditions (unique names) to use.
## @param [$n] Use start to set condition, stop to remove it.
## @return Echo: Current scripts or conditions.
## @return Code: 0 when conditions are valid, 1 otherwise.
loopstop() {
	local cond_dir="$shellm/media/script/loopstop"
	[ ! -d "$cond_dir" ] && mkdir "$cond_dir"
	[ -z "$1" ] && { /bin/ls "$cond_dir"; return; }
	
	local short_name="${1##*/}"
	if [ -z "$2" ]; then
		local list=$(/bin/ls "$cond_dir/$short_name" 2>/dev/null)
		local ret=$?
		[ $ret -ne 0 ] && return $ret
		[ -z "$list" ] && /bin/rm -rf "$cond_dir/$short_name"
		echo "$list"
	fi
	
    shift
	local stop_var n=0 ret=0 i
	while [ $# -ne 0 ]; do
		stop_var[$n]="$1"
		shift
		let n++
	done
	[ -z "$stop_var" ] && return 1
	
	if [ ! -d "$cond_dir/$short_name" ]; then
		mkdir "$cond_dir/$short_name"
	fi
	
	case ${stop_var[$(( n-1 ))]} in
		'start')
			for ((i=0; i<n-1; i++)); do
				echo > "$cond_dir/$short_name/${stop_var[$i]}"
			done
		;;
		'stop')
			for ((i=0; i<n-1; i++)); do
				/bin/rm "$cond_dir/$short_name/${stop_var[$i]}" 2>/dev/null
			done
		;;
		*)
			for ((i=0; i<n; i++)); do
				if [ ! -f "$cond_dir/$short_name/${stop_var[$i]}" ]; then
					ret=1
					break
				fi
			done
			echo $ret
		;;
	esac
}

fi # __LOOPSTOP_SH


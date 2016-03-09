if ndef __STANDALONE_SH; then
define __STANDALONE_SH

## @file standalone.sh
## @brief Provides standalone function

## @brief Take a script as input and output its standalone version
## (no include directives). Recursive function.
## @param $1 Relative/Full path to the input script
## @return Standalone script on stdout
standalone() {
	[ $# -lt 2 ] && return 1
	local input
	local output="$2"

	if [ -f "$1" ]; then
		input="$1"
	elif [ -f "$cgBin/$1" ]; then
		input="$cgBin/$1"
	else
		return 1
	fi

	local list="TEMP_STD_LIST"

	if [ "$3" != "--" ]; then
		echo "#!/bin/bash" > "$output"
		touch "$list"
	fi

	local inclusion def
	for inclusion in $(/bin/grep "include " "$input" | /usr/bin/cut -d' ' -f2); do
		if ! /bin/grep -q "$inclusion" "$list"; then
			echo "$inclusion" >> "$list"
			for def in $(/bin/grep "define " "$cgLib/$inclusion" | /usr/bin/cut -d' ' -f2-); do
				case $def in
					*" "*) echo "${def/ /=}" ;;
					*) ;;
				esac
			done
			/bin/grep -v -e "^include " -e "^define " -e "^if ndef " -e "^fi #" "$cgLib/$inclusion"
			standalone "$cgLib/$inclusion" "$output" --
		fi
	done >> "$output"

	if [ "$3" != "--" ]; then
		/bin/grep -v -e '^#!/bin/bash' -e "^include " "$input" >> "$output"
		/bin/rm "$list"
	fi
}

fi # __STANDALONE_SH

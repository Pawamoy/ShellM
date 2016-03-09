if ndef __QUESTION_SH; then
define __QUESTION_SH

include switchCG.sh
include message.sh

cgQuestionConfirm=
cgQuestionTimeout=-1

set_question_timeout() {
	cgQuestionTimeout=${1:-$cgQuestionTimeout}
}

unset_question_timeout() {
	cgQuestionTimeout=-1
}

question_cli() {
	local a timeout
	[ ${cgQuestionTimeout:--1} -ne -1 ] &&
		timeout="-t $cgQuestionTimeout" 
	if read $timeout -p "$* " a; then
		case $a in
			[Yy]|[Yy][Ee][Ss]) return 0 ;;
			[Nn]|[Nn][Oo]) return 1 ;;
			[Aa]|[Yy][Aa]|[Yy][Aa][Ll][Ll]) return 2 ;;
			[Qq]|[Nn][Aa]|[Nn][Aa][Ll][Ll]) return 3 ;;
			*) return 1 ;;
		esac
	else
		echo
		return 1
	fi
}

question_gui() {
	local timeout yad
	[ ${cgQuestionTimeout:--1} -ne -1 ] &&
		timeout="--timeout=$cgQuestionTimeout" 
	yad="/usr/bin/yad $timeout \
		--question \
		--text '$*'"
	[ -n "$cgQuestionConfirm" ] &&
		yad="$yad --button 'Yes:0' \
		--button 'No:1' \
		--button 'Yes to all:2' \
		--button 'No to all:3'"
	eval "$yad"
	[ $? -eq 70 ] && return 1
}

activate_question_extra() {
	cgQuestionConfirm=help
}

deactivate_question_extra() {
	cgQuestionConfirm=
}

question() {
	case ${cgQuestionConfirm} in
		"") switchCG "question_cli '$*'" "question_gui '$*'"
			case $? in
				0|2) return 0 ;;
				1|3) return 1 ;;
			esac
		;;
		help)
			err "*** y:yes / n:no / a:yes-to-all / q:no-to-all"
			cgQuestionConfirm=ask
			question "$@"
		;;
		ask)
			switchCG "question_cli '$*'" "question_gui '$*'"
			case $? in
				0|1) return $? ;;
				2) cgQuestionConfirm=yes-to-all; return 0 ;;
				3) cgQuestionConfirm=no-to-all; return 1 ;;
			esac
		;;
		yes-to-all) return 0 ;;
		no-to-all) return 1 ;;
	esac
}

fi # __QUESTION_SH

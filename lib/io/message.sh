if ndef __MESSAGE_SH; then
define __MESSAGE_SH

## @file message.sh
## @brief Provide useful message functions

include color.sh

## @fn void color (color, message)
## @brief Set the color to color, and output message if given
## @param $1 Color to use (see baseColor(3) and envColor(3))
## @param [$2] Message to display (reset to default color after display)
## @return Echo: Color code [and message]
color() { [ -z "$2" ] && echo -e -n "$1" || echo -e "$1$2\033[00m"; }

## @fn int end (exit_code)
## @brief Exit if subshell, return if interactive shell
## @param [$1] Exit code
## @return Code: exit_code (default 1)
end() {
  case "${0#-}" in
    bash|zsh|csh|ksh|sh|dash)
      kill -INT $$ ;;
    *) exit ${1:-1} ;;
  esac
}

_status_message() {
  color $1 >&2
  printf " %-7s " "$2" >&2
  color $c_default
  printf ' '; shift
}

## @fn void err (error)
## @brief Output message on stderr (&2)
## @param $1 Message to display
## @return Echo: message on stderr
err() {
  [ $# -gt 1 ] && { _status_message ${c_error:-$c_red} "$1"; shift; }
  echo -e "$1" >&2
}

## @fn int die (error, exit_code)
## @brief Output message on stderr (&2), then exit/return
## @param $1 Message to display
## @return Code: exit_code (default 1)
## @return Echo: message on stderr
die() { err "$1"; end ${2:-1}; }

## @fn void pause (message)
## @brief Output message on stderr (&2), then wait for Enter
## @param $1 Message to display
## @return Echo: message on stderr
pause() { err "$1"; read -p "Press Enter -- "; }

## @fn void line (char)
## @brief Print a line composed of character char
## @param $1 Character to use
## @return Echo: a line on stderr
line() {
  local i l=${#1} c=$(/usr/bin/tput cols)
  if [ $l -gt 1 ]; then
    local n=$((c/l)); local r=$((c-(n*l)))
    err "$(for ((i=0; i<$n; i++)); do echo -n $1; done; echo -n ${1:0:$r})"
  else
    err "$(for ((i=0; i<$c; i++)); do echo -n $1; done)"
  fi
}

fi # __MESSAGE_SH

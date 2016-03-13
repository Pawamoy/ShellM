if ndef __LOG_SH; then
define __LOG_SH

## @file log.sh
## @brief Provide message logging functions

LOG_FD=3

## @fn void activate_log ()
## @brief Redirect file descriptor LOG_FD of the current shell in shellm/log/$0
## @pre Variable shellm is defined
## @seealso log
activate_log() {
	[ ! -e /proc/$$/fd/$LOG_FD ] &&
		eval "exec $LOG_FD>>\"$shellm/log/${0##*/}\""
}

## @fn void deactivate_log ()
## @brief Cancel redirections of the current shell
## @seealso log
deactivate_log() { eval "exec $LOG_FD>&-"; }

## @fn void log (message)
## @brief Redirect message stdout and stderr on LOG_FD file descriptor,
## prefixed with date-time and current script name
## @param $1 Message to log
## @return Echo: message on LOG_FD file descriptor
log() {
	eval "echo \"[$(/bin/date '+%F %T')] (${0##*/})  $1\" >&$LOG_FD 2>&1" 2>/dev/null
}

fi # __LOG_SH
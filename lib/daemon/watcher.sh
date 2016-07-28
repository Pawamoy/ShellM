if ndef __DAEMON_SH; then
define  __DAEMON_SH "EMPTY_TIME LOCKED_TIME
                    dir_command file_command
                    dir_move file_move dir_empty
                    _lock _unlock _locked
                    file_lock file_unlock file_locked
                    dir_lock dir_unlock dir_locked
                    watch"

## \brief Provide functions to ease creation of daemon scripts

EMPTY_TIME=2
LOCKED_TIME=0.5

dir_command() {
  echo "Replace this command with your own."
  echo "First argument (\$1) is the relative path to a directory to process."
}

file_command() {
  echo "Replace this command with your own."
  echo "First argument (\$1) is the relative path to a file to process."
}

dir_move() {
  mv "$1" "$2"
}

file_move() {
  mv "$1" "$2"
}

dir_empty() {
  ( [ -d "${1:-.}" ] && cd "${1:-.}"; [ "$(echo .* *)" = ". .. *" ]; )
}

_lock() {
  touch "$SETLOCK_DIR/${1##*/}"
}

_unlock() {
  rm "$SETLOCK_DIR/${1##*/}"
}

_locked() {
  [ -e "$GETLOCK_DIR/${1##*/}" ]
}

file_lock() {
  _lock "$1"
}

file_unlock() {
  _unlock "$1"
}

file_locked() {
  _locked "$1"
}

dir_lock() {
  _lock "$1"
}

dir_unlock() {
  _unlock "$1"
}

dir_locked() {
  _locked "$1"
}

watch() {
  local item
  mkdir -p "$GETLOCK_DIR"
  mkdir -p "$SETLOCK_DIR"
  while true; do
    [ -d "$1" ] || { sleep $3; continue; }
    if ! dir_empty "$1"; then
      echo
      for item in "$1"/*; do
        if [ -d "$item" ]; then
          dir_locked "$item" && { sleep $4; continue; }
          dir_command "$item"
          dir_lock "$item"
          dir_move "$item" "$2"
          dir_unlock "$item"
        else
          file_locked "$item" && { sleep $4; continue; }
          file_command "$item"
          file_lock "$item"
          file_move "$item" "$2"
          file_unlock "$item"
        fi
      done
    else
      sleep $3
    fi
  done
}

fi # __DAEMON_SH

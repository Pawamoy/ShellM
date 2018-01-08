# TODO: move in init.sh

if shellm-ndef __CORE_FIND_SH; then
shellm-define __CORE_FIND_SH "find find_script find_lib"

# TODO: move this in shellm-project (if really needed)

## \fn find_script [NAME]
## \brief Find a script.
find_script() {
  local found
  if [ $# -eq 1 ]; then
    if [ -f "$1" ]; then
      found="$1"
    elif [ -f "${SHELLM_USR}/bin/$1" ]; then
      found="${SHELLM_USR}/bin/$1"
    else
      echo "find_script: can't find $1" >&2
      return 1
    fi
  elif [ -f "$0" ]; then
    found="$0"
  elif [ -f "${SHELLM_USR}/bin/$0" ]; then
    found="${SHELLM_USR}/bin/$0"
  else
    echo "find_script: can't find $0" >&2
    return 1
  fi

  echo "${found}"
}

## \fn find_lib <NAME>
## \brief Find a library file.
find_lib() {
  local found
  if [ -f "$1" ]; then
    found="$1"
  elif [ -f "${SHELLM_USR}/lib/$1" ]; then
    found="${SHELLM_USR}/lib/$1"
  else
    echo "find_lib: can't find $1" >&2
    return 1
  fi

  echo "${found}"
}

## \fn find NAME
## \brief Find either a script or a library file.
find() {
  local found
  if found=$(find_script "$@" 2>/dev/null); then
    echo "${found}"
  elif found=$(find_lib "$@" 2>/dev/null); then
    echo "${found}"
  else
    echo "find: can't find $1" >&2
    return 1
  fi
}

fi  # __CORE_FIND_SH

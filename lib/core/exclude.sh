if ndef __CORE_EXCLUDE_SH; then
define __CORE_EXCLUDE_SH "exclude"

exclude() {
  local current_lib
  local include includes lib_header def defined

  # TODO: use find lib instead
  if [ -f "$1" ]; then
    current_lib="$1"
  elif [ -f "${SHELLM_USR}/lib/$1" ]; then
    current_lib="${SHELLM_USR}/lib/$1"
  elif [ -f "${SHELLM_ROOT}/lib/$1" ]; then
    current_lib="${SHELLM_ROOT}/lib/$1"
  else
    echo "shellm: exclude: no such file: $1 (from $0)"
  fi

  lib_header=${current_lib#${SHELLM_USR}/lib/}
  lib_header=${lib_header//[\/.]/_}
  lib_header=__${lib_header^^}
  defined=${!lib_header}
  for def in ${defined}; do
    case "$(type -t "${def}")" in
      function)
        # shellcheck disable=SC2163
        unset -f "${def}"
      ;;
      alias)
        # shellcheck disable=SC2163
        unalias "${def}"
      ;;
      "")
        # shellcheck disable=SC2163
        unset "${def}"
      ;;
    esac
  done
  unset "${lib_header}"

  # recurse on other included libraries
  # FIXME: #8 fix incomplete regex
  includes=$(grep -Eo "include [\"']?[a-zA-Z_/]*\.sh[\"']?" "${current_lib}" | cut -d' ' -f2 | sed "s/[\"']//g")
  for include in ${includes}; do
    exclude "${include}"
  done
}

fi  # __CORE_EXCLUDE_SH

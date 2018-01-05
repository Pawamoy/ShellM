if shellm-ndef __CORE_INIT_EXPORT_SH; then
shellm-define __CORE_INIT_EXPORT_SH "init_export"

## \brief Improve scripts performance by [recursively] exporting used libraries

shellm-include core/shellman.sh

## \fn init_export ()
## \brief Parse all sub-scripts (recursively) and export their includes
init_export() {
  local current_script
  local sub_script sub_scripts
  local include includes include_header defined

  # TODO: use find lib instead
  if [ $# -eq 1 ]; then
    current_script="$1"
  elif [ -f "$0" ]; then
    current_script="$0"
  else
    current_script="${SHELLM_USR}/bin/$0"
  fi
  sub_scripts=$(shellman_get export "${current_script}")
  for sub_script in ${sub_scripts}; do
    # FIXME: #8 fix incomplete regex
    # shellcheck disable=SC2154
    includes=$(grep -Eo "include [\"']?[a-zA-Z_/]*\.sh[\"']?" "${SHELLM_USR}/bin/${sub_script}" | cut -d' ' -f2)
    for include in ${includes}; do
      include "${include}"
      include_header=${include//[\/.]/_}
      include_header=__${include_header^^}
      include_header=${!include_header}
      for defined in ${include_header}; do
        if [ "$(type -t "${defined}")" = "function" ]; then
          # shellcheck disable=SC2163
          export -f "${defined}"
        else
          # shellcheck disable=SC2163
          export "${defined}"
        fi
      done
    done
    init_export "${SHELLM_USR}/bin/${sub_script}"
  done
}

fi # __CORE_INIT_DATA_SH

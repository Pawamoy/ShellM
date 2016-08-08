if ndef __CORE_INIT_EXPORT_SH; then
define __CORE_INIT_EXPORT_SH "init_export"

## \brief Improve scripts performance by [recursively] exporting libraries
## of sub-scripts from the current top-script.

# TODO: export tag in shellman

include core/shellman.sh

## \fn init_export ()
## \brief Parse all sub-scripts (recursively) and export their includes
init_export() {
  local sub_script sub_scripts
  local include includes include_header defined

  sub_scripts=$(shellman_get export "${1:-$0}")
  for sub_script in $sub_scripts; do
    includes=$(grep -o 'include [a-zA-Z_/]*\.sh' $shellm/bin/$sub_script | cut -d' ' -f2)
    for include in $includes; do
      include $include
      include_header=${include//[\/.]/_}
      include_header=__${include_header^^}
      include_header=${!include_header}
      for defined in $include_header; do
        if [ "$(type -t $defined)" = "function" ]; then
          export -f $defined
        else
          export $defined
        fi
      done
    done
    init_export "$shellm/bin/$sub_script"
  done
}

fi # __CORE_INIT_DATA_SH
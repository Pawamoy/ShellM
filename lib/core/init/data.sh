
if ndef __CORE_INIT_DATA_SH; then
define __CORE_INIT_DATA_SH "init_data"

## \fn init_data [script]
## \brief Initialize DATADIR variable and create directory
## \out Path to data directory
init_data() {
  local script="${1:-$0}"
  local data_dir="${shellm}/usr/data/${script##*/}"
  mkdir -p "${data_dir}" 2>/dev/null
  echo "${data_dir}"
}

## \fn get_data_dir [script]
## \brief Echo the path to data directory
## \out Path to data directory
get_data_dir() {
  local script="${1:-$0}"
  echo "${shellm}/usr/data/${script##*/}"
}

fi # __CORE_INIT_DATA_SH

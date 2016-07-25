
if ndef __CORE_INIT_DATA_SH; then
define __CORE_INIT_DATA_SH

## \fn init ()
## \brief Initialize DATADIR variable and create directory
init_data() {
  DATADIR="${shellm}/usr/data/${0##*/}"
  mkdir -p "${DATADIR}" 2>/dev/null
}

fi # __CORE_INIT_DATA_SH

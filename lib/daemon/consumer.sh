if ndef __DAEMON_CONSUMER_SH; then
define  __DAEMON_CONSUMER_SH "
  consumer_lock
  consumer_unlock
  consumer_locked
  consumer_unlocked
  consumer_send
  consumer_get
  consumer_empty
  consumer_consume
  consumer"

include core/init/data.sh

## \brief Provide functions to ease creation of daemon scripts
## \desc Simple consumers:
##
## Multiple consumers can consume the same directory.
## Each time a consumer wants to process a file, it tries to lock it.
## To lock it, it tries to create a directory named after the sha256 sum of
## the file name (file being a regular file or a directory).
## If the lock fails, it means the file is being processed by another consumer,
## and the consumer continue to the next file.
## If the lock succeeds, the consumer process the file, move the file,
## and then remove the lock.
## If all files in the directory are locked, consumers wait a certain amount of
## time before trying again to process files.
## If the directory is empty, consumers wait a certain amount of time before
## listing it again.
##
## Chained-consumers:
##
## Multiple directories can each be consumed by several consumers (note: a
## consumer consumes one and only one directory). The processed files transit
## from one directory to another, until they finally land in a not-consumed
## directory. In each directory, they are processed accordingly to what the
## consumers for this directory are doing (example: filter video files ->
## extract audio -> reencode to specific format -> normalize to N decibels ->
## move to final music folder)
## For a particular directory, consumers behave exactly like simple consumers,
## except for the following:
##
##     In addition to setting a lock for the current
##     directory when processing a file, consumers also set a lock (with the
##     potential post-process name of the file) for the next directory in the
##     chain. This is done to avoid files being processed by the next consumers
##     before the files are completely moved to the next directory.
##
## Variables that can be overwritten as global variables in script:
##
## consumed_dir
## empty_wait
## locked_wait
## next_daemon
## next_location

sha() {
  echo "${1##*/}" | sha256sum | cut -d' ' -f1
}

## \fn consumer_lock NAME DIR
## \param NAME Name of the item to lock
## \param DIR Directory in which to create the lock
consumer_lock() {
  mkdir "${2:-$set_lock_dir}/$(sha "$1")" 2>/dev/null
}

consumer_unlock() {
  rm -rf "${2:-$set_lock_dir}/$(sha "$1")" 2>/dev/null
}

consumer_locked() {
  [ -d "${2:-$get_lock_dir}/$(sha "$1")" ]
}

consumer_unlocked() {
  ! consumer_locked
}

consumer_send() {
  echo # TODO
}

consumer_get() {
  echo # TODO
}

consumer_empty() {
  local dir="${1:-$consumed_dir}"
  ( [ -d "${dir}" ] && cd "${dir}"; [ "$(echo .* *)" = ". .. *" ]; )
}

consumer_consume() {
  # compute the post-process file name
  postprocess_name="$1"
  # dummy process: rename file to postprocess_name
  [ "$1" != "${postprocess_name}" ] && mv "$1" "${postprocess_name}"
  # typically delete remaining useless files
  # remove obsolete locks
  if [ "$1" != "${postprocess_name}" ]; then
    [ -e "$1" ] && rm -rf "$1"
    consumer_unlock "$1"
  fi

  consumer_unlock "$1"
}

## \fn consumer [options] [command]
## \brief Main consumer function
consumer() {
  local command
  get_lock_dir=$(init_data)
  set_lock_dir="${get_lock_dir}"

  while [ $# -ne 0 ]; do
    case $1 in
      ## \param consume DIR
      ## Directory to consume
      consume) consumed_dir="$2"; shift ;;
      ## \param empty-wait SECONDS
      ## Time to wait when consumed directory is empty
      empty-wait) empty_wait="$2"; shift ;;
      ## \param locked-wait SECONDS
      ## Time to wait when item is locked
      locked-wait) locked_wait="$2"; shift ;;
      ## \param chained-with DAEMON
      ## Next processing daemon in case of chain
      chained-with) next_daemon="$2"; shift ;;
      ## \param move-to DIR
      ## Where to move the files once processed.
      ## This option is ignored if chained-with is given
      move-to) next_location="$2"; shift ;;
      ## \param (command) get ITEM...
      ## Move specified items into consumed directory
      get) command=get; shift; break ;;
      ## \param (command) send ITEM... DIR
      ## Move specified items from consumed directory into specified DIR
      send) command=send; shift; break ;;
      ## \param (command) location
      ## Return the path of the consumed directory
      location) command=location; shift; break ;;
    esac
    shift
  done

  if [ ! -d "${consumed_dir}" ]; then
    echo "consumer: consumed dir ${consumed_dir} does not exist" >&2
    exit 1
  fi

  case $command in
    get) consumer_get "$@"; exit $? ;;
    send) consumer_send "$@"; exit $? ;;
    location) echo "${consumed_dir}"; exit 0 ;;
  esac

  if [ -z "${empty_wait}" ]; then
    empty_wait=2
  fi

  if [ -z "${locked_wait}" ]; then
    locked_wait=0.5
  fi

  if [ -n "${next_daemon}" ]; then
    local next_location=$(${next_daemon} location)
    local next_set_lock_dir=$(init_data "${next_daemon}")
  fi

  local all_locked item
  while true; do
    if ! consumer_empty "${consumed_dir}"; then
      all_locked=true
      for item in "${consumed_dir}"/*; do
        if consumer_lock "${item}"; then
          all_locked=false
          consumer_consume "${item}" "${next_location}" "${next_set_lock_dir}"
        fi
      done
      ${all_locked} && sleep ${locked_wait}
    else
      sleep ${empty_wait}
    fi
  done
}

fi # __DAEMON_CONSUMER_SH

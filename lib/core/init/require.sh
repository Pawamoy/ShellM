if ndef __CORE_INIT_REQUIRE_SH; then
define __CORE_INIT_REQUIRE_SH "
  list_requirements
  list_missing_requirements
  install_requirement
  install_requirements
  install_missing_requirements
  check_requirements"

include core/find.sh

## \fn list_requirements [script]
## \brief Recursively list the requirements of a script.
list_requirements() {
  local current_script
  local sub_script sub_scripts

  current_script="$(find_script "$@")"
  shellman_get require "${current_script}"
  sub_scripts=$(shellman_get export "${current_script}")
  for sub_script in ${sub_scripts}; do
    list_requirements "${SHELLM_USR}/bin/${sub_script}"
  done
}

## \fn list_missing_requirements [script]
## \brief Recursively list the missing requirements of a script.
list_missing_requirements() {
  local require manager package

  for require in $(list_requirements "$@"); do
    manager=${require%%:*}
    package=${require#*:}
    case "${manager}" in
      apt)
        if ! dpkg -s "${package}" >/dev/null 2>&1; then
          echo "${require}"
        fi
      ;;
      npm)
        if ! npm ls -g --parseable --depth=0 | grep -q "/${package}$"; then
          echo "${require}"
        fi
      ;;
      pip)
        if ! pip freeze | grep -q "^${package}==.*"; then
          echo "${require}"
        fi
      ;;
      pip3)
        if ! pip3 freeze | grep -q "^${package}==.*"; then
          echo "${require}"
        fi
      ;;
    esac
  done
}

install_requirement() {
  local manager package
  manager=${1%%:*}
  package=${1#*:}
  case "${manager}" in
    apt) sudo apt-get install -y "${package}" ;;
    npm) sudo npm install -g "${package}" ;;
    pip) sudo -H pip install "${package}" ;;
    pip3) sudo -H pip3 install "${package}" ;;
  esac
}

install_requirements() {
  local require

  for require in $(list_requirements "$@"); do
    install_requirement "${require}"
  done
}

install_missing_requirements() {
  local require

  for require in $(list_missing_requirements "$@"); do
    install_requirement "${require}"
  done
}

check_requirements() {
  local missing answer ok ctn current_script

  current_script="$(find_script "$@")"
  missing=$(list_missing_requirements "${current_script}")

  if [ -n "${missing}" ]; then
    # shellcheck disable=SC2086
    echo "Some requirements are missing:" ${missing}
    read -rp "Would you like to install them? [Yn] " answer

    case "${answer}" in
      y|Y|yes|YES) ok=true ;;
      n|N|no|NO) ok=false ;;
      *) ok=true ;;
    esac

    if ${ok}; then
      if ! shellm-install-requirements --missing "${current_script}"; then
        read -rp "Some requirement installation failed, would you like to continue anyway? [yN] " answer
        case "${answer}" in
          y|Y|yes|YES) ctn=true ;;
          n|N|no|NO) ctn=false ;;
          *) ctn=false ;;
        esac
        ! ${ctn} && exit 10
      fi
    fi
  fi
}

fi # __CORE_INIT_REQUIRE_SH

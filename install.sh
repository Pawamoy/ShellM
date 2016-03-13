#!/bin/bash

READLINK=$(which readlink)
DIRNAME=$(which dirname)
RM=$(which rm)
LN=$(which ln)
GIT=$(which git)

SCRIPT_LOCATION=${BASH_SOURCE[0]}
if [ -x "${READLINK}" ]; then
  while [ -L "${SCRIPT_LOCATION}" ]; do
    SCRIPT_LOCATION=$("${READLINK}" -e "${SCRIPT_LOCATION}")
  done
fi
PARENT_DIR="$(cd "$("${DIRNAME}" "${SCRIPT_LOCATION}")" && pwd)"

USE_QUESTION="How do you want to use shellm?"
USE_OPTIONS=(
  "Always (appends 2 lines in .bashrc)"
  "By loading it with an alias 'loadshellm'"
)

REPO_QUESTION="Would you like to clone your shellm/usr git repository? (needs git)"
REPO_OPTIONS=(
  "Yes"
  "No"
)

REPO_URL_QUESION="Please enter the full URL of the repository: "


install_always() {
  local bashrc_content
  bashrc_content="# shellm\nexport shellm=\"${PARENT_DIR}\"\n. \"\${shellm}/usr/shellmrc\"\n"
  printf "${bashrc_content}" >> "${HOME}/.bashrc"
  echo "The following lines have been added to ${HOME}/.bashrc:"
  echo
  echo "${bashrc_content}"
}

install_alias() {
  local alias_content
  alias_content="alias loadshellm='export shellm=\"${PARENT_DIR}\"; . \"\${shellm}/usr/shellmrc\"'"
  echo "${alias_content}" >> "${HOME}/.bash_aliases"
  echo "The following line has been added to ${HOME}/.bash_aliases:"
  echo
  echo "${alias_content}"
}

clone_user_repo() {
  "${GIT}" clone "${REPO_URL}" "${PARENT_DIR}/usr"
}

create_empty_user_repo() {
  cp -r "${PARENT_DIR}/usr-template" "${PARENT_DIR}/usr"
}

main() {
  echo "${USE_QUESTION}"
  select _ in "${USE_OPTIONS[@]}"; do
    case ${REPLY} in
      1) install_always; break ;;
      2) install_alias; break ;;
    esac
  done
  echo "${REPO_QUESTION}"
  select _ in "${REPO_OPTIONS[@]}"; do
    case ${REPLY} in
      1)
        read -p "${REPO_URL_QUESION}" REPO_URL
        clone_user_repo
        break
      ;;
      2)
        create_empty_user_repo
        break
      ;;
    esac
  done
}

main

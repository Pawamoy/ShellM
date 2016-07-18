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
  "Always (write in .bashrc)"
  "With an alias (write in .bash_aliases)"
  "Just tell me the commands"
)

REPO_QUESTION="Would you like to clone your shellm/usr git repository? (needs git)"
REPO_OPTIONS=(
  "Yes"
  "No (creates an new user directory from template)"
)

REPO_URL_QUESION="Please enter the full URL of the repository: "

LOGO="\e[7m
                                                        
            _|                  _|  _|                  
    _|_|_|  _|_|_|      _|_|    _|  _|  _|_|_|  _|_|    
  _|_|      _|    _|  _|_|_|_|  _|  _|  _|    _|    _|  
      _|_|  _|    _|  _|        _|  _|  _|    _|    _|  
  _|_|_|    _|    _|    _|_|_|  _|  _|  _|    _|    _|  
                                                        
\e[0m"

install_always() {
  local bashrc_content
  bashrc_content="# shellm\nexport shellm=\"${PARENT_DIR}\"\n. \"\${shellm}/usr/shellmrc\"\n"
  printf "${bashrc_content}" >> "${HOME}/.bashrc"
  echo "The following lines have been added to ${HOME}/.bashrc:"
  echo
  echo "${bashrc_content}"
  echo
}

install_alias() {
  local alias_content
  alias_content="alias loadshellm='export shellm=\"${PARENT_DIR}\"; . \"\${shellm}/usr/shellmrc\"'"
  echo "${alias_content}" >> "${HOME}/.bash_aliases"
  echo "The following line has been added to ${HOME}/.bash_aliases:"
  echo
  echo "${alias_content}"
  echo
}

install_none() {
  echo "Load shellm with these 2 commands:"
  echo
  echo "export shellm=${PARENT_DIR}"
  echo ". \$shellm/usr/shellmrc"
  echo
}

clone_user_repo() {
  "${GIT}" clone "${REPO_URL}" "${PARENT_DIR}/usr"
}

create_new_user_dir() {
  cp -r "${PARENT_DIR}/usr-template" "${PARENT_DIR}/usr"
}



main() {
  echo -e "${LOGO}"
  echo "${USE_QUESTION}"
  select _ in "${USE_OPTIONS[@]}"; do
    case ${REPLY} in
      1) install_always; break ;;
      2) install_alias; break ;;
      3) install_none; break ;;
    esac
  done
  printf "\e[7m%56s\e[0m\n" " "
  echo
  echo "${REPO_QUESTION}"
  select _ in "${REPO_OPTIONS[@]}"; do
    case ${REPLY} in
      1)
        read -p "${REPO_URL_QUESION}" REPO_URL
        clone_user_repo
        break
      ;;
      2)
        create_new_user_dir
        break
      ;;
    esac
  done
}

main

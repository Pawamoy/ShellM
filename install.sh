#!/bin/bash

READLINK=$(which readlink)
DIRNAME=$(which dirname)
RM=$(which rm)
LN=$(which ln)
GIT=$(which git)

SCRIPT_LOCATION=${BASH_SOURCE[0]}
if [ -x "$READLINK" ]; then
  while [ -L "$SCRIPT_LOCATION" ]; do
    SCRIPT_LOCATION=$("$READLINK" -e "$SCRIPT_LOCATION")
  done
fi
PARENT_DIR="$(cd "$("$DIRNAME" "$SCRIPT_LOCATION")" && pwd)"

USE_QUESTION="How do you want to use shellm?"
USE_OPTIONS=(
  "Always (appends 2 lines in .bashrc)"
  "At the invocation of 'shellm'"
)

INVOK_QUESTION="Create this command by..."
INVOK_OPTIONS=(
  "Appending an alias in .bash_aliases"
  "Create a symbolic link in /usr/bin (may need root privilege)"
)

REPO_QUESTION="Would you like to clone your shellm/usr git repository? (needs git)"
REPO_OPTIONS=(
  "Yes"
  "No"
)

REPO_URL_QUESION="Please enter the full URL of the repository: "

install_always() {
  printf "\n\n# shellm\nexport shellm=$PARENT_DIR\n. \$shellm/shellmrc\n" >> "$HOME/.bashrc"
}

install_alias() {
  printf "\n\nalias shellm='\"$PARENT_DIR/shellm\"'\n" >> "$HOME/.bash_aliases"
}

install_symlink() {
  sudo "$RM" /usr/bin/shellm 2>/dev/null
  sudo "$LN" -s "$PARENT_DIR/shellm" /usr/bin/shellm
}

start_shellm() {
  "$PARENT_DIR/shellm" --discover
}

main() {
  echo "$USE_QUESTION"
  select _ in "${USE_OPTIONS[@]}"; do
    case $REPLY in
      1) install_always; break ;;
      2)
        echo "$INVOK_QUESTION"
        select _ in "${INVOK_OPTIONS[@]}"; do
          case $REPLY in
            1) install_alias; break ;;
            2) install_symlink; break ;;
          esac
        done
        break
      ;;
    esac
  done
  echo "$REPO_QUESTION"
  select _ in "${REPO_OPTIONS[@]}"; do
    case $REPLY in
      1)
        read -p "$REPO_URL_QUESION" REPO_URL
        "$GIT" clone "$REPO_URL" "$PARENT_DIR/usr"
        break
      ;;
      2) break ;;
    esac
  done
  start_shellm
}

main

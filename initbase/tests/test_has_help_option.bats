load data

_has_help_option() {
  local script status=${success}
  for script in "$@"; do
    if ! "${script}" --help >/dev/null; then
      echo "${script}: no help option"
      status=${failure}
    fi
  done
  return ${status}
}

@test "scripts have a help option" {
  skip "Running scripts can have unintended, dangerous side effects"
  _has_help_option ${scripts}
}

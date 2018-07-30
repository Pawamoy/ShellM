load data

@test "shellcheck on init.sh" {
  shellcheck -x "init.sh"
}

@test "shellcheck on scripts" {
  if [ ! -n "${scripts}" ]; then
    skip "there no scripts to check"
  fi
  shellcheck -x ${scripts}
}

@test "shellcheck on libraries" {
  if [ ! -n "${libs}" ]; then
    skip "there no libraries to check"
  fi
  shellcheck -xe SC2148 ${libs}
}

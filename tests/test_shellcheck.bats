load data

@test "shellcheck on init.sh" {
  shellcheck -x "init.sh"
}

@test "shellcheck on scripts" {
  shellcheck -x ${scripts}
}

@test "shellcheck on libraries" {
  shellcheck -xe SC2148 ${libs}
}

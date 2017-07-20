load data

@test "shellcheck_init" {
  shellcheck -x "${SHELLM_ROOT}/init.sh"
}

@test "shellcheck_scripts" {
  shellcheck -x ${scripts}
}

@test "shellcheck_libs" {
  shellcheck -xe SC2148 ${libs}
}

load data

@test "shellm source-path runs correctly" {
  run shellm source-path
  assert_success
}

@test "shellm source-path fails with unsupported shell (argument)" {
  run shellm source-path notshell
  assert_failure
}

@test "shellm source-path fails with unsupported shell (inherited BASHER_SHELL)" {
  BASHER_SHELL=notshell run shellm source-path
  assert_failure
}

@test "shellm source-path prints help with -h option" {
  run shellm source-path -h
  assert_success
  assert_output HELP
}

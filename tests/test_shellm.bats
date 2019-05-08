load data

@test "shellm prints usage and fails with no arguments" {
  run shellm
  assert_failure
  assert_line -n 0 "usage: shellm COMMAND [ARGS]"
  assert_line -n 1 "Type 'shellm help' to print the list of commands."
}

@test "shellm prints help with -h option" {
  run shellm -h
  assert_success
  # assert_line -n1
}

@test "shellm fails with unknown command" {
  run shellm not_a_command
  assert_failure
  assert_output "shellm: no such command 'not_a_command'"
}

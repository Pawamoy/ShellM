load data

@test "shellm source fails with no arguments" {
  run shellm source
  assert_failure
  assert_line -n 0 "usage: shellm source [-hf] <LIBRARY>"
}

@test "shellm source sources a library only once" {
  double_source() {
    shellm source some_lib
    shellm source some_lib
  }

  run double_source
  assert_success
  assert_output "I've been sourced!"
}

@test "shellm source fails to source inexistant library" {
  run shellm source inexistent
  assert_failure
  assert_output "shellm: source: no such file in LIBPATH: 'inexistent'"
}

@test "shellm source return error code from failing library" {
  run shellm source failing_lib
  assert_failure 45
  assert_output "shellm: source: error while sourcing '${BATS_TEST_DIRNAME}/fixtures/lib/failing_lib'"
}

@test "shellm source prints help with -h option" {
  skip "not ready"
  run shellm source -h
  assert_success
  assert_output ""
}

@test "shellm source forces re-sourcing of library with -f option" {
  double_source() {
    shellm source some_lib
    shellm source -f some_lib
  }

  run double_source
  assert_success
  assert_line -n 0 "I've been sourced!"
  assert_line -n 1 "I've been sourced!"
}

@test "shellm source with directory sources files in lib subdir" {
  run shellm source some_dir_lib
  assert_success
  assert_line -n 0 "file 1"
  assert_line -n 1 "file 2"
}

load data

@test "shellm locate finds library file" {
  run shellm locate some_lib
  assert_success
  assert_output "${BATS_TEST_DIRNAME}/fixtures/lib/some_lib"
}

@test "shellm locate finds library directory" {
  run shellm locate some_dir_lib
  assert_success
  assert_output "${BATS_TEST_DIRNAME}/fixtures/lib/some_dir_lib"
}

@test "shellm locate fails to locate inexitent file" {
  run shellm locate inexistent
  assert_failure
  assert_output ""
}

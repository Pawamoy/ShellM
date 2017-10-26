load data

@test "project skeleton passes the tests" {
  rm -rf /tmp/shellm-skeleton || true
  shellm init /tmp/shellm-skeleton
  shellm load /tmp/shellm-skeleton/profile
  shellm test
  rm -rf /tmp/shellm-skeleton || true
}

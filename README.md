![logo](logo.png)

[![Build Status](https://gitlab.com/shellm/shellm/badges/master/build.svg)](https://gitlab.com/shellm/shellm)

shellm is some kind of Bash framework,
used to write scripts or libraries in Bash (mostly).

It lets you define a `LIBPATH` variable.
Just like `PATH`, `LIBPATH` is a semi-colon separated list of directories.
You will then be able to source files from these directories
with `shellm source`.

## Installation
Installation is done with [basher](https://github.com/basherpm/basher):

```bash
basher install gitlab.com/shellm/shellm
include shellm/shellm/init.sh  # include function comes from basher
```

### Dependencies
To run the test suite, also install these:

- [bats](https://github.com/sstephenson/bats):
  ```bash
  basher install bats-core/bats-core
  ```
- [shellcheck](https://github.com/koalaman/shellcheck):
  ```bash
  curl -Ls https://storage.googleapis.com/shellcheck/shellcheck-stable.linux.x86_64.tar.xz | tar xJ
  sudo mv shellcheck-stable/shellcheck /usr/bin/shellcheck
  rm -rf shellcheck-stable
  ```

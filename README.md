# shellm

[![Build Status](https://travis-ci.org/Pawamoy/shellm.svg?branch=master)](https://travis-ci.org/Pawamoy/shellm)

Manage your scripts and libraries, write documentation directly in files and
auto-generate help options (-h, --help) and man pages, sync your working
environment on any remote or physical machine.

## Download

For now shellm is only on GitHub:

`git clone https://github.com/Pawamoy/shellm.git`

## Installation

An installation script is available in the root folder:

```bash
cd shellm
./install.sh
```
It will simply install its dependencies
(like [shellman](https://github.com/Pawamoy/shellman)),
and let you choose how you want to use it (at startup/invocation).
It will also offer to clone your shellm user repository (see the documentation
for more details), or create an empty one.

## Documentation

It is all on the [wiki](https://github.com/Pawamoy/shellm/wiki).
You can already jump to the
[Quick concept section](https://github.com/Pawamoy/shellm/wiki#quick-concept).

## Tests

To run all the tests, just use `./test.sh`. Append a `-h` option to print
some help.

- For the linting tests you will need the latest version of
  [ShellCheck](https://github.com/koalaman/shellcheck):

  ```bash
  sudo curl -Lso /usr/bin/shellcheck https://github.com/caarlos0/shellcheck-docker/releases/download/v0.4.4/shellcheck
  sudo chmod +x /usr/bin/shellcheck
  ```

- For the compatibility tests you will need
  [checkbashisms](https://sourceforge.net/projects/checkbaskisms/):

  ```bash
  sudo apt-get install devscripts
  ```

![logo](logo.png)

[![Build Status](https://travis-ci.org/Pawamoy/shellm.svg?branch=master)](https://travis-ci.org/Pawamoy/shellm)

Manage your scripts and libraries, write documentation directly in files and
auto-generate help options (-h, --help) and man pages, sync your working
environment on any remote or physical machine.

## Download

For now shellm is only on GitHub:

`git clone https://github.com/Pawamoy/shellm.git`

## Dependencies

- shellman: `[sudo -H] pip install shellman`

## Installation

Installation is inspired from **pyenv** and others:

```bash
git clone https://github.com/Pawamoy/shellm.git ~/.shellm
# in your .bashrc
export SHELLM_ROOT="${HOME}/.shellm"
. "${SHELLM_ROOT}/init.sh"
```

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
  sudo curl -Lso /usr/bin/shellcheck https://github.com/caarlos0/shellcheck-docker/releases/download/v0.4.5/shellcheck
  sudo chmod +x /usr/bin/shellcheck
  ```

- For the compatibility tests you will need
  [checkbashisms](https://sourceforge.net/projects/checkbaskisms/):

  ```bash
  sudo apt-get install devscripts
  ```

![logo](logo.png)

[![Build Status](https://travis-ci.org/Pawamoy/shellm.svg?branch=master)](https://travis-ci.org/Pawamoy/shellm)

Shellm is some kind of Bash framework. It provides useful commands to help you
write and manage your shell scripts. See the Quickstart section below to get an
idea of what Shellm can do for you!

## Installation
Installation is done by cloning the repo and sourcing the code
from `.bashrc` (or another file sourced at terminal startup):

```bash
git clone https://github.com/Pawamoy/shellm.git ~/.shellm
echo -e '\n. ~/.shellm/init.sh' >> .bashrc
```

### Dependencies
- [shellman](https://github.com/Pawamoy/shellman): `[sudo -H] pip install shellman`

## Documentation
Documentation can be found on the [GitHub wiki](https://github.com/Pawamoy/shellm/wiki).

## Quickstart
Shellm is basically a set of functions and command-line scripts.
It lets you manage all your shell scripts and shell libraries within a single
directory, allowing you to easily synchronize your shell environment and
configuration across your different machines or servers (i.e. with CVS).

The main benefits from using Shellm are:
- just two lines appended in `.bashrc`, and you can put all the rest into
  your shellm user configuration
- fast creation and edition of scripts
- a C-like library inclusion system
- automatic help options and automatic man pages generation thanks to Shellman
  documentation
- already some shell libraries available (need your feedback!)
- already working test suite

## Tests
To run the tests you will need to install some dependencies:

- [bats](https://github.com/sstephenson/bats):
  ```bash
  curl -Lo- "https://raw.githubusercontent.com/bpkg/bpkg/master/setup.sh" | sudo bash
  sudo bpkg install -g sstephenson/bats
  ```
- [shellcheck](https://github.com/koalaman/shellcheck):
  ```bash
  sudo curl -Lso /usr/bin/shellcheck https://github.com/caarlos0/shellcheck-docker/releases/download/v0.4.5/shellcheck
  sudo chmod +x /usr/bin/shellcheck
  ```
- [checkbashisms](https://sourceforge.net/projects/checkbaskisms/) (optional) and pcregrep:
  ```bash
  sudo apt-get install devscripts pcregrep
  ```

Now simply run `bats tests`!

<p align="center">
  <img src="https://gl.githack.com/shellm/core/raw/master/logo.png">
</p>

<h1 align="center">Be a Shell Master!</h1>

<p align="center">... or a Shell Magician? a Shell Mage? Anyway: it's a shell library sourcing system.</p>

<p align="center">
  <a href="https://gitlab.com/shellm/core/commits/master">
    <img alt="pipeline status" src="https://gitlab.com/shellm/core/badges/master/pipeline.svg" />
  </a>
  <!--<a href="https://gitlab.com/shellm/core/commits/master">
    <img alt="coverage report" src="https://gitlab.com/shellm/core/badges/master/coverage.svg" />
  </a>-->
  <a href="https://gitter.im/shellm/core">
    <img alt="gitter chat" src="https://badges.gitter.im/shellm/core.svg" />
  </a>
</p>

`shellm` is a library sourcing / loading system.

It lets you define a `LIBPATH` variable.
Just like `PATH`, `LIBPATH` is a semi-colon separated list of directories.
You will then be able to source files from these directories
with `shellm source`.

<h2 align="center">Demo</h2>
<p align="center"><img src="https://gl.githack.com/shellm/core/raw/master/demo/demo.svg"></p>

## Installation
Installation is done with [basher](https://github.com/basherpm/basher):

```bash
basher install gitlab.com/shellm/core
```

## Usage
If you want to use shellm in your current shell or in a script,
simply enter the following instruction
or add it at the beginning of your script:

```bash
source $(shellm-core-path)
```

You now have access to the `shellm-source` command
which allows you to source a file located somewhere in your `LIBPATH`.

Typically, for a package installed with basher:
```bash
shellm-source namespace/package
# or just a specific file:
# shellm-source namespace/package/lib/main.sh
```

For files listed in a personal directory, something like
```
/path/to/my/lib/
├── bookmark.sh
├── cd.sh
└── env
    ├── aliases.sh
    ├── completion.sh
    └── goenv.sh
```

...and `LIBPATH=/path/to/my/lib:$LIBPATH`:

```bash
shellm-source bookmark.sh
shellm-source env/aliases.sh
```

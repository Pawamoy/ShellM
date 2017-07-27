#!/bin/bash

# download z
cd "${SHELLM_USR}/ext"
git clone https://github.com/rupa/z

# create lib binding
cat >"${SHELLM_USR}/lib/ext/z.sh" <<EOF
if ndef __EXT_Z_SH; then
define  __EXT_Z_SH "z"
. "\${SHELLM_USR}/ext/z/z.sh"
fi  # __EXT_Z_SH
EOF

# create man page symlink
cd "${SHELLM_USR}/man/man1"
ln -s ../../ext/z/z.1

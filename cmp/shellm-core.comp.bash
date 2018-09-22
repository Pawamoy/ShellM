complete -W "$(compgen -c | grep shellm- | sed 's/shellm-//')" shellm
# FIXME: should be dynamic, and switch to geiven command completion

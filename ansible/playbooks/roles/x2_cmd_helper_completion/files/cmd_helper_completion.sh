#!/bin/bash

_my_script_completions() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts="--rosdep --build --build_ccache --autoware --autoware-main --autoware-main-mrm --autoware-start --autoware-stop --autoware-restart --psim-main --psim-main-mrm --autoware-sub --psim-sub --psim --start_record --stop_record --kill --clean --help"

    mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")
    return 0
}
complete -F _my_script_completions cmd_helper.sh

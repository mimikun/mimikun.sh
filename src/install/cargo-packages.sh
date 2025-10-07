#!/bin/bash

function existsCmd() {
    type -a "$1" >/dev/null 2>&1
}

# HACK: tabiew can't build
install_cargo_tabiew() {
    echo "compiling \"tabiew\" takes a SO LONG time"
    echo "can't install it from crates.io"
}

# HACK: rustowl can't build
install_cargo_rustowl() {
    echo "compiling \"rustowl\" takes a SO LONG time"
    echo "can't install it from crates.io"
}

#task_id=$(pueue add -p -- "echo TEMP_TASK")

while read -r line; do
    if ! existsCmd "$line"; then
        echo "$line is not found"
        case "$line" in
        "tabiew")
            update_cargo_tabiew
            ;;
        "rustowl")
            update_cargo_rustowl
            ;;
        *)
            if [ "$1" == "--no-pueue" ]; then
                cargo install "$line"
            else
                pueue add -- "cargo install $line"
                #task_id=$(pueue add --after "$task_id" -p -- "cargo install $line")
            fi
            ;;
        esac
    fi
done <"$HOME/.mimikun-pkglists/linux_cargo_packages.txt"

# Install from sources
if [ "$1" == "--no-pueue" ]; then
    cargo install --git https://github.com/Adarsh-Roy/gthr --locked
else
    pueue add -- "cargo install --git https://github.com/Adarsh-Roy/gthr --locked"
    #task_id=$(pueue add --after "$task_id" -p -- "cargo install $line")
fi

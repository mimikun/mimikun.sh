#!/bin/bash

# magic
before_sudo() {
    if ! test "$(
        sudo uname >>/dev/null
        echo $?
    )" -eq 0; then
        exit 1
    fi
}

arch() {
    # Upgrade packages
    sudo pacman -Syu
    # Cleaning packages
    sudo pacman -Rns "$(pacman -Qtdq)" 2>/dev/null || true
    sudo pacman -Sc
    sudo pacman -Scc
}

before_sudo
arch

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

# Ubuntu
ubuntu() {
    # Upgrade APT repogitory list
    sudo apt update
    # Upgrade APT packages
    sudo apt upgrade -y
    # Cleaning APT caches
    sudo apt autoremove -y
    sudo apt-get clean
}

before_sudo
ubuntu

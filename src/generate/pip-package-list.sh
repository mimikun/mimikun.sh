#!/bin/bash

pip freeze |
    sed \
        -e "s/=.*//g" \
        -e "s/ @.*//g" |
    LC_ALL=C sort > \
        "$HOME/.mimikun-pkglists/linux_pip_packages.txt"

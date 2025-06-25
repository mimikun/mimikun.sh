#!/bin/bash

while read -r line; do
    if [ "$1" == "--no-pueue" ]; then
        pnpm install --global "$line"
    else
        pueue add -- "pnpm install --global $line"
    fi
done <"$HOME/.mimikun-pkglists/linux_pnpm_packages.txt"

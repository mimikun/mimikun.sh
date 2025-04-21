#!/bin/bash

while read -r line; do
    echo "Install: $line"
    pueue add -- "uv tool install $line"
done <"$HOME/.mimikun-pkglists/linux_uv_tools.txt"

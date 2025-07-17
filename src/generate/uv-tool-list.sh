#!/bin/bash

uv tool list |
    grep "v[0-9]" |
    sed -e "s/\s.*//g" |
    LC_ALL=C sort >"$HOME/.mimikun-pkglists/linux_uv_tools.txt"

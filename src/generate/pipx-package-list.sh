#!/bin/bash

pipx list --short |
    cut -d " " -f 1 |
    LC_ALL=C sort > \
        "$HOME/.mimikun-pkglists/linux_pipx_packages.txt"

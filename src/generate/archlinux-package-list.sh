#!/bin/bash

# description: Print a list of explicitly installed Arch Linux packages

# From Official Repository
sudo pacman -Qqen |
    LC_ALL=C sort >"$HOME/.mimikun-pkglists/linux_arch_official_packages.txt"

# From Arch User Repository
sudo pacman -Qqem |
    LC_ALL=C sort >"$HOME/.mimikun-pkglists/linux_arch_aur_packages.txt"

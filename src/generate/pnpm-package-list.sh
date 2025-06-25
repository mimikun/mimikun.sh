#!/bin/bash

pnpm list --global --json |
    jq --raw-output ".[].dependencies | keys[]" |
    sort >"$HOME/.mimikun-pkglists/linux_pnpm_packages.txt"

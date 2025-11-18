#!/bin/bash

# DEPRECATED: This script is deprecated in favor of uv-tool-list.ts
# Please use the TypeScript version for cross-platform support:
#   deno run -A src/generate/uv-tool-list.ts
# or
#   deno task generate:uv-tools

uv tool list |
    grep "v[0-9]" |
    sed -e "s/\s.*//g" |
    LC_ALL=C sort >"$HOME/.mimikun-pkglists/linux_uv_tools.txt"

#!/bin/bash

set -euo pipefail

# Default package list file location
PACKAGE_LIST="${1:-$HOME/.mimikun-pkglists/archlinux-packages.txt}"

# Check if package list file exists
if [[ ! -f "$PACKAGE_LIST" ]]; then
    echo "Error: Package list file not found: $PACKAGE_LIST" >&2
    echo "Usage: $0 [package-list-file]" >&2
    echo "Default: ~/.mimikun-pkglists/archlinux-packages.txt" >&2
    exit 1
fi

# Check if paru is installed
if ! command -v paru &> /dev/null; then
    echo "Error: paru is not installed" >&2
    exit 1
fi

echo "Installing packages from: $PACKAGE_LIST"

# Read package list and install one by one
while IFS= read -r package || [[ -n "$package" ]]; do
    # Skip empty lines and comments
    [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue

    # Trim whitespace
    package=$(echo "$package" | xargs)

    echo "Installing: $package"
    if paru -S --noconfirm "$package"; then
        echo "✓ Successfully installed: $package"
    else
        echo "✗ Failed to install: $package" >&2
    fi
    echo
done < "$PACKAGE_LIST"

echo "Package installation complete"

#!/bin/bash

if [ "$1" == "--no-pueue" ]; then
    pnpm update --global
else
    pueue add -- "pnpm update --global"
fi

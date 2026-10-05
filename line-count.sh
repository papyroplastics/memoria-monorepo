#!/usr/bin/env bash

pattern='(Containerfile|Caddyfile|Makefile|CMakeLists.txt|\.(c(c|pp)?|h(pp)?|py|kts?|sh|ya?ml|tf|cmake))$'

function fd-pat {
    fd --no-follow --type file "$pattern" "$1"
}

function fd-module {
    echo "-- Module: $1 -- "
    fd-pat "$1" | xargs wc -l --total=auto
}

fd-module application
fd-module backend
fd-module firmware
fd-module shared

echo "-- Total -- "
fd-pat . | xargs wc -l --total=only


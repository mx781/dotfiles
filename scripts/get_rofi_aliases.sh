#!/bin/bash

get_defined_functions() {
    declare -F | awk '{print $NF}' | grep -vP "^_" | grep -vP 'nvm'
}

get_defined_aliases() {
    alias | awk -F'[ =]' '{print $2}'
}

main() {
    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi
    if [ -f ~/.bash_aliases ]; then
        source ~/.bash_aliases
    fi
    get_defined_functions
    get_defined_aliases
}

main

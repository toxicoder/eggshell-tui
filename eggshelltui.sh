#!/bin/bash

# EggshellTUI Framework
# A lightweight framework for building TUIs in Bash/Zsh

# Check for Bash 4+ or Zsh 5+
if [ -n "$BASH_VERSION" ]; then
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        echo "Error: EggshellTUI requires Bash 4.0 or higher." >&2
        exit 1
    fi
elif [ -n "$ZSH_VERSION" ]; then
     if [[ "${ZSH_VERSION%%.*}" -lt 5 ]]; then
        echo "Error: EggshellTUI requires Zsh 5.0 or higher." >&2
        exit 1
    fi
fi

# Global configuration
declare -A ACTIONS

# Function to execute actions
eggshelltui_execute_action() {
    local action="$1"
    shift

    if [[ -n "${ACTIONS[$action]}" ]]; then
        "${ACTIONS[$action]}" "$@"
    else
        echo "Error: Unknown action '$action'" >&2
        exit 1
    fi
}

# Backend detection
eggshelltui_detect_backend() {
    if command -v dialog >/dev/null 2>&1; then
        EGGSHELLTUI_BACKEND="dialog"
    elif command -v whiptail >/dev/null 2>&1; then
        EGGSHELLTUI_BACKEND="whiptail"
    else
        EGGSHELLTUI_BACKEND="text"
    fi
}

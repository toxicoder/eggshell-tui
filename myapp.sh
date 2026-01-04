#!/bin/bash

source eggshelltui.sh

# 1. Define Logic (CLI)
function cli_demo_menu() {
    echo "Running Menu Demo..."
}

function cli_demo_input() {
    echo "You entered: $1"
}

# 2. Define Screens (TUI)

function screen_main() {
    eggshelltui_menu "EggshellTUI Component Demo" \
        "input" "Input Box Demo" \
        "checklist" "Checklist Demo" \
        "radiolist" "Radiolist Demo" \
        "yesno" "Yes/No Dialog Demo" \
        "msgbox" "Message Box Demo" \
        "gauge" "Progress Bar Demo" \
        "textbox" "Text Box (File Viewer) Demo" \
        "exit" "Exit Application"

    local choice=$?

    case $choice in
        1) CURRENT_SCREEN="input" ;;
        2) CURRENT_SCREEN="checklist" ;;
        3) CURRENT_SCREEN="radiolist" ;;
        4) CURRENT_SCREEN="yesno" ;;
        5) CURRENT_SCREEN="msgbox" ;;
        6) CURRENT_SCREEN="gauge" ;;
        7) CURRENT_SCREEN="textbox" ;;
        8) clear; exit 0 ;;
        *) clear; exit 0 ;; # Cancel
    esac
}

function screen_input() {
    eggshelltui_input "What is your favorite color?" USER_COLOR "Blue"
    if [ $? -eq 0 ]; then
        eggshelltui_msgbox "Result" "You chose: $USER_COLOR"
    fi
    CURRENT_SCREEN="main"
}

function screen_checklist() {
    eggshelltui_checklist "Select Fruits" FRUIT_SELECTION \
        "apple" "Apple" "on" \
        "banana" "Banana" "off" \
        "orange" "Orange" "off"

    if [ $? -eq 0 ]; then
        eggshelltui_msgbox "Result" "You selected: $FRUIT_SELECTION"
    fi
    CURRENT_SCREEN="main"
}

function screen_radiolist() {
    eggshelltui_radiolist "Select Difficulty" DIFFICULTY \
        "easy" "Easy Mode" "on" \
        "medium" "Medium Mode" "off" \
        "hard" "Hard Mode" "off"

    if [ $? -eq 0 ]; then
        eggshelltui_msgbox "Result" "Difficulty set to: $DIFFICULTY"
    fi
    CURRENT_SCREEN="main"
}

function screen_yesno() {
    eggshelltui_yesno "Confirmation" "Do you like this framework?"
    if [ $? -eq 0 ]; then
        eggshelltui_msgbox "Response" "Glad to hear it!"
    else
        eggshelltui_msgbox "Response" "We will try to improve."
    fi
    CURRENT_SCREEN="main"
}

function screen_msgbox() {
    eggshelltui_msgbox "Information" "This is a simple message box.\nIt wraps text automatically and supports responsive resizing."
    CURRENT_SCREEN="main"
}

function screen_gauge() {
    # Simulate progress
    for i in {0..100..10}; do
        eggshelltui_gauge "Loading..." "Processing data" "$i"
        sleep 0.1
    done
    eggshelltui_msgbox "Done" "Process completed."
    CURRENT_SCREEN="main"
}

function screen_textbox() {
    # Show the script itself as an example
    eggshelltui_textbox "Source Code Viewer" "eggshelltui.sh"
    CURRENT_SCREEN="main"
}

# 3. Main Entry
if [[ "$1" == "--tui" ]]; then
    CURRENT_SCREEN="main"
    eggshelltui_enter_loop
else
    echo "Usage: $0 --tui"
    echo "This demo is primarily for testing TUI components."
fi

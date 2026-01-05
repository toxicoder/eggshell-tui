#!/bin/bash

source eggshelltui.sh

function screen_main() {
    eggshelltui_menu "System Monitor" \
        "dashboard" "Dashboard" \
        "procs" "Process Manager" \
        "settings" "Settings" \
        "about" "About" \
        "exit" "Exit"

    local choice=$?

    case $choice in
        1) CURRENT_SCREEN="dashboard" ;;
        2) CURRENT_SCREEN="procs" ;;
        3) CURRENT_SCREEN="settings" ;;
        4) CURRENT_SCREEN="about" ;;
        5) clear; exit 0 ;;
        *) clear; exit 0 ;; # Cancel
    esac
}

function screen_dashboard() {
    # Simulate gathering data
    eggshelltui_infobox "System Monitor" "Gathering system metrics..."
    sleep 1

    # Simulated Gauge
    for i in {10..80..10}; do
        eggshelltui_gauge "CPU Usage" "Analyzing cores..." "$i"
        sleep 0.1
    done

    # Display Results
    eggshelltui_msgbox "System Status" \
        "Uptime: $(uptime | cut -d, -f1)\n\nCPU Load: 0.45, 0.32, 0.15\nMemory: 4.2GB / 16GB used\nDisk: 45% used (/)"

    CURRENT_SCREEN="main"
}

function screen_settings() {
    local -a config_form
    eggshelltui_form "Configuration" config_form \
        "Refresh Rate (s):" "5" \
        "Theme:" "Dark" \
        "Log Level:" "Info"

    if [ $? -eq 0 ]; then
        eggshelltui_msgbox "Saved" "Settings updated:\nRate: ${config_form[0]}\nTheme: ${config_form[1]}\nLog: ${config_form[2]}"
    fi

    CURRENT_SCREEN="main"
}

function screen_procs() {
    local proc_to_kill=""

    eggshelltui_radiolist "Process Manager" proc_to_kill \
        "cpu_hog" "CPU Stress Test (PID 1023)" "off" \
        "mem_leak" "Memory Leaker (PID 4055)" "off" \
        "idle_proc" "Idle Process (PID 9921)" "off" \
        "sys_daemon" "System Daemon (PID 88)" "off"

    if [ $? -eq 0 ] && [ -n "$proc_to_kill" ]; then
        if eggshelltui_yesno "Terminate Process" "Are you sure you want to kill $proc_to_kill?"; then
            eggshelltui_infobox "Killing..." "Sending SIGTERM..."
            sleep 1
            eggshelltui_msgbox "Success" "Process $proc_to_kill has been terminated."
        else
            eggshelltui_msgbox "Cancelled" "Process was not touched."
        fi
    fi

    CURRENT_SCREEN="main"
}

function screen_about() {
    eggshelltui_msgbox "About SysMon" "SysMon v1.0\n\nA demonstration utility for EggshellTUI.\n\nCreated for educational purposes."
    CURRENT_SCREEN="main"
}

# Main Entry
if [[ "$1" == "--tui" ]]; then
    CURRENT_SCREEN="main"
    eggshelltui_enter_loop
else
    echo "Usage: $0 --tui"
    echo "Run with --tui to start the System Monitor TUI."
fi

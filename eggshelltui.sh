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

# --- Core Functions ---

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

# Initialize backend
eggshelltui_detect_backend

# Helper to get terminal dimensions
eggshelltui_get_dims() {
    EGGSHELLTUI_LINES=$(tput lines)
    EGGSHELLTUI_COLS=$(tput cols)
}

# Helper to calculate window size (e.g., 80% of screen)
eggshelltui_calc_size() {
    eggshelltui_get_dims
    local h_pct=${1:-80}
    local w_pct=${2:-80}

    # Calculate dimensions
    EGGSHELLTUI_HEIGHT=$(( (EGGSHELLTUI_LINES * h_pct) / 100 ))
    EGGSHELLTUI_WIDTH=$(( (EGGSHELLTUI_COLS * w_pct) / 100 ))

    # Minimum constraints
    if [ "$EGGSHELLTUI_HEIGHT" -lt 5 ]; then EGGSHELLTUI_HEIGHT=5; fi
    if [ "$EGGSHELLTUI_WIDTH" -lt 20 ]; then EGGSHELLTUI_WIDTH=20; fi
}

# --- UI Components ---

# 1. Menu Component
# Usage: eggshelltui_menu "Title" "Option1" "Desc1" "Option2" "Desc2" ...
# Returns: 1-based index of selection via $?
eggshelltui_menu() {
    local title="$1"
    shift

    # Responsive sizing
    eggshelltui_calc_size 80 60

    local choice=""
    local -a options=("$@")

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        # Calculate menu height (window height - borders/title)
        local menu_height=$(( EGGSHELLTUI_HEIGHT - 6 ))

        # Capture output to a temp file because dialog/whiptail writes result to stderr
        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --clear --title "$title" \
               --menu "" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" "$menu_height" \
               "${options[@]}" 2>"$temp_file"

        local ret=$?
        choice=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
            # Find index of choice
            local idx=1
            for ((i=0; i<${#options[@]}; i+=2)); do
                if [ "${options[i]}" == "$choice" ]; then
                    return $idx
                fi
                ((idx++))
            done
        fi
        return 0 # Cancel/Esc returns 0 in this logic context for index?
                 # Wait, standard unix: 0 is success.
                 # But prompt said: "returns the index of the selected option (1-based)"
                 # This implies we can't use `return` for the index effectively if it goes > 255.
                 # But shell return is 8-bit.
                 # Let's assume return code is used for status (OK/Cancel), and we set a global variable for result.
                 # Re-reading README usage: "eggshelltui_menu ... CHOICE=$?"
                 # Okay, so it relies on exit code. This limits options to 255. That's fine for simple menus.
                 # dialog returns 0 on OK, 1 on Cancel.
                 # So if OK (0), we return the index.

        if [ $ret -ne 0 ]; then return 0; fi # Cancelled

    elif [ "$EGGSHELLTUI_BACKEND" == "text" ]; then
        echo "=== $title ==="
        local idx=1
        for ((i=0; i<${#options[@]}; i+=2)); do
            echo "$idx) ${options[i]} - ${options[i+1]}"
            ((idx++))
        done
        read -p "Select an option: " choice
        # validate input
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt "$idx" ] && [ "$choice" -gt 0 ]; then
             return "$choice"
        fi
        return 0
    fi
}

# 2. Input Component
# Usage: eggshelltui_input "Prompt" VAR_NAME [InitialValue]
eggshelltui_input() {
    local prompt="$1"
    local var_name="$2"
    local init_val="$3"

    eggshelltui_calc_size 20 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --title "Input" --inputbox "$prompt" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" "$init_val" 2>"$temp_file"
        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
            if [ -n "$BASH_VERSION" ]; then
                printf -v "$var_name" '%s' "$result"
            else
                read -r "$var_name" <<< "$result"
            fi
            return 0
        else
            return 1
        fi
    else
        echo "$prompt"
        if [ -n "$BASH_VERSION" ]; then
            read -e -i "$init_val" input_val
            printf -v "$var_name" '%s' "$input_val"
        elif [ -n "$ZSH_VERSION" ]; then
            # Zsh fallback using vared for line editing with initial value
            local temp_val="$init_val"
            vared -p "" -c temp_val
            read -r "$var_name" <<< "$temp_val"
        else
             # POSIX fallback (no initial value editing)
             read -r input_val
             read -r "$var_name" <<< "$input_val"
        fi
        return 0
    fi
}

# 3. InfoBox Component
# Usage: eggshelltui_infobox "Title" "Message"
eggshelltui_infobox() {
    local title="$1"
    local message="$2"

    eggshelltui_calc_size 50 70

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        $EGGSHELLTUI_BACKEND --title "$title" --infobox "$message" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH"
        # Infobox doesn't wait for input, typically used with sleep or background tasks
    else
        echo "=== $title ==="
        echo "$message"
    fi
}

# 4. MsgBox Component (Modal with OK)
# Usage: eggshelltui_msgbox "Title" "Message"
eggshelltui_msgbox() {
    local title="$1"
    local message="$2"

    eggshelltui_calc_size 50 70

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        $EGGSHELLTUI_BACKEND --title "$title" --msgbox "$message" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH"
    else
        echo "=== $title ==="
        echo "$message"
        read -p "Press Enter to continue..."
    fi
}

# 5. Yes/No Component
# Usage: eggshelltui_yesno "Title" "Message"
# Returns 0 for Yes, 1 for No
eggshelltui_yesno() {
    local title="$1"
    local message="$2"

    eggshelltui_calc_size 20 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        $EGGSHELLTUI_BACKEND --title "$title" --yesno "$message" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH"
        return $?
    else
        echo "=== $title ==="
        echo "$message"
        while true; do
            read -p " (y/n): " yn
            case $yn in
                [Yy]* ) return 0;;
                [Nn]* ) return 1;;
            esac
        done
    fi
}

# 6. Checklist Component (Multi-select)
# Usage: eggshelltui_checklist "Title" VAR_NAME "Tag1" "Item1" "ON/OFF" "Tag2" "Item2" "ON/OFF" ...
eggshelltui_checklist() {
    local title="$1"
    local var_name="$2"
    shift 2

    eggshelltui_calc_size 80 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        local menu_height=$(( EGGSHELLTUI_HEIGHT - 6 ))
        local temp_file=$(mktemp)

        $EGGSHELLTUI_BACKEND --title "$title" --checklist "Select options:" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" "$menu_height" \
            "$@" 2>"$temp_file"

        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$result"
             else
                 read -r "$var_name" <<< "$result"
             fi
             return 0
        else
             return 1
        fi
    else
        # Simplified text fallback: just list them
        echo "=== $title ==="
        echo "Note: Multi-select not fully supported in text mode fallback yet."
        return 1
    fi
}

# 7. Radiolist Component (Single select)
# Usage: eggshelltui_radiolist "Title" VAR_NAME "Tag1" "Item1" "ON/OFF" ...
eggshelltui_radiolist() {
    local title="$1"
    local var_name="$2"
    shift 2

    eggshelltui_calc_size 80 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        local menu_height=$(( EGGSHELLTUI_HEIGHT - 6 ))
        local temp_file=$(mktemp)

        $EGGSHELLTUI_BACKEND --title "$title" --radiolist "Select option:" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" "$menu_height" \
            "$@" 2>"$temp_file"

        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$result"
             else
                 read -r "$var_name" <<< "$result"
             fi
             return 0
        else
             return 1
        fi
    else
        echo "=== $title ==="
        # Reuse menu logic could work here but simpler to warn
        echo "Radio list fallback not implemented."
        return 1
    fi
}

# 8. Gauge Component (Progress bar)
# Usage: eggshelltui_gauge "Title" "Message" PERCENT
eggshelltui_gauge() {
    local title="$1"
    local message="$2"
    local percent="$3"

    eggshelltui_calc_size 20 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        echo "$percent" | $EGGSHELLTUI_BACKEND --title "$title" --gauge "$message" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" 0
    else
        echo "[$title] $message: $percent%"
    fi
}

# 9. TextBox Component (File viewer)
# Usage: eggshelltui_textbox "Title" FILEPATH
eggshelltui_textbox() {
    local title="$1"
    local filepath="$2"

    eggshelltui_calc_size 90 90

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        # Note: whiptail might use --scrolltext or different flags for file viewer, but --textbox is standard.
        # However, whiptail --textbox often requires --scrolltext to be useful, but let's stick to base compatibility.
        $EGGSHELLTUI_BACKEND --title "$title" --textbox "$filepath" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH"
    else
        echo "=== $title ==="
        cat "$filepath" | less
    fi
}

# 10. Password Component
# Usage: eggshelltui_password "Prompt" VAR_NAME [InitialValue]
eggshelltui_password() {
    local prompt="$1"
    local var_name="$2"
    local init_val="$3"

    eggshelltui_calc_size 20 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ] || [ "$EGGSHELLTUI_BACKEND" == "whiptail" ]; then
        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --title "Password" --passwordbox "$prompt" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" "$init_val" 2>"$temp_file"
        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
            if [ -n "$BASH_VERSION" ]; then
                printf -v "$var_name" '%s' "$result"
            else
                read -r "$var_name" <<< "$result"
            fi
            return 0
        else
            return 1
        fi
    else
        echo "$prompt"
        # read -s for silent input
        if [ -n "$BASH_VERSION" ]; then
            read -s -p "Password: " input_val
            echo "" # Newline after silent read
            printf -v "$var_name" '%s' "$input_val"
        else
            # POSIX sh doesn't always support -s, but zsh does.
            stty -echo
            read -r input_val
            stty echo
            echo ""
            read -r "$var_name" <<< "$input_val"
        fi
        return 0
    fi
}

# 11. Form Component (Multiple Inputs)
# Usage: eggshelltui_form "Title" ARRAY_VAR_NAME "Label1" "Init1" "Label2" "Init2" ...
eggshelltui_form() {
    local title="$1"
    local var_name="$2"
    shift 2

    eggshelltui_calc_size 80 60
    local -a fields=("$@")
    local -a form_args
    local row=1

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ]; then
        for ((i=0; i<${#fields[@]}; i+=2)); do
            # Label Y X Item Y X FLen ILen
            form_args+=("${fields[i]}" "$row" 1 "${fields[i+1]}" "$row" 20 40 100)
            ((row++))
        done

        local form_height=$(( row + 2 ))
        if [ "$form_height" -gt "$EGGSHELLTUI_HEIGHT" ]; then form_height=$EGGSHELLTUI_HEIGHT; fi

        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --title "$title" --form "Enter details:" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" "$form_height" \
            "${form_args[@]}" 2>"$temp_file"

        local ret=$?

        if [ $ret -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 mapfile -t "$var_name" < "$temp_file"
             elif [ -n "$ZSH_VERSION" ]; then
                 local -a lines
                 lines=("${(@f)$(<"$temp_file")}")
                 eval "$var_name=(\"\${lines[@]}\")"
             fi
             rm -f "$temp_file"
             return 0
        else
             rm -f "$temp_file"
             return 1
        fi

    else
        # Fallback for whiptail and text (Wizard style)
        local -a collected_values
        for ((i=0; i<${#fields[@]}; i+=2)); do
            local l="${fields[i]}"
            local init="${fields[i+1]}"
            local temp_res=""

            eggshelltui_input "$l ($((i/2+1))/${#fields[@]})" temp_res "$init"
            if [ $? -ne 0 ]; then return 1; fi
            collected_values+=("$temp_res")
        done

        if [ -n "$BASH_VERSION" ]; then
             # Securely copy the array
             local declare_str
             declare_str=$(declare -p collected_values)
             # Repackage into new name
             eval "${declare_str/collected_values/$var_name}"
        elif [ -n "$ZSH_VERSION" ]; then
             # Zsh assignment is generally safer but eval is still tricky.
             # Use (P) for indirect reference if possible, but we are writing TO it.
             # set -A var_name "${collected_values[@]}"
             # Using eval with quoting is standard in Zsh for dynamic naming if careful.
             # We need to escape contents to be safe in eval.
             # (q) flag in Zsh quotes words.
             eval "$var_name=(\${(q)collected_values[@]})"
        fi
        return 0
    fi
}

# 12. Calendar Component
# Usage: eggshelltui_calendar "Title" VAR_NAME [Day] [Month] [Year]
eggshelltui_calendar() {
    local title="$1"
    local var_name="$2"
    local day="${3:-$(date +%d)}"
    local month="${4:-$(date +%m)}"
    local year="${5:-$(date +%Y)}"

    eggshelltui_calc_size 60 60 # Calendar needs less space

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ]; then
        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --title "$title" --calendar "Select date:" 0 0 "$day" "$month" "$year" 2>"$temp_file"
        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
             # Dialog returns DD/MM/YYYY.
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$result"
             else
                 read -r "$var_name" <<< "$result"
             fi
             return 0
        else
            return 1
        fi
    else
        # Fallback
        local current_date="$year-$month-$day"
        local input_date=""
        eggshelltui_input "Enter Date (YYYY-MM-DD):" input_date "$current_date"
        if [ $? -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$input_date"
             else
                 read -r "$var_name" <<< "$input_date"
             fi
             return 0
        else
            return 1
        fi
    fi
}

# 13. Timebox Component
# Usage: eggshelltui_timebox "Title" VAR_NAME [Hour] [Minute] [Second]
eggshelltui_timebox() {
    local title="$1"
    local var_name="$2"
    local hour="${3:-$(date +%H)}"
    local min="${4:-$(date +%M)}"
    local sec="${5:-$(date +%S)}"

    eggshelltui_calc_size 60 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ]; then
        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --title "$title" --timebox "Select time:" 0 0 "$hour" "$min" "$sec" 2>"$temp_file"
        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
             # Dialog returns HH:MM:SS
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$result"
             else
                 read -r "$var_name" <<< "$result"
             fi
             return 0
        else
            return 1
        fi
    else
        # Fallback
        local current_time="$hour:$min:$sec"
        local input_time=""
        eggshelltui_input "Enter Time (HH:MM:SS):" input_time "$current_time"
        if [ $? -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$input_time"
             else
                 read -r "$var_name" <<< "$input_time"
             fi
             return 0
        else
            return 1
        fi
    fi
}

# 14. Range Component (Slider)
# Usage: eggshelltui_range "Title" VAR_NAME Min Max Default
eggshelltui_range() {
    local title="$1"
    local var_name="$2"
    local min="$3"
    local max="$4"
    local def="$5"

    eggshelltui_calc_size 60 60

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ]; then
        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --title "$title" --rangebox "Select value:" 0 0 "$min" "$max" "$def" 2>"$temp_file"
        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$result"
             else
                 read -r "$var_name" <<< "$result"
             fi
             return 0
        else
            return 1
        fi
    else
        # Fallback
        local input_val=""
        eggshelltui_input "Enter Value ($min - $max):" input_val "$def"
        if [ $? -eq 0 ]; then
             # TODO: Validate range?
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$input_val"
             else
                 read -r "$var_name" <<< "$input_val"
             fi
             return 0
        else
            return 1
        fi
    fi
}

# 15. File Select Component
# Usage: eggshelltui_fileselect "Title" VAR_NAME [InitialPath]
eggshelltui_fileselect() {
    local title="$1"
    local var_name="$2"
    local init_path="${3:-.}"

    eggshelltui_calc_size 80 80

    if [ "$EGGSHELLTUI_BACKEND" == "dialog" ]; then
        local temp_file=$(mktemp)
        $EGGSHELLTUI_BACKEND --title "$title" --fselect "$init_path" "$EGGSHELLTUI_HEIGHT" "$EGGSHELLTUI_WIDTH" 2>"$temp_file"
        local ret=$?
        local result=$(<"$temp_file")
        rm -f "$temp_file"

        if [ $ret -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$result"
             else
                 read -r "$var_name" <<< "$result"
             fi
             return 0
        else
            return 1
        fi
    else
        # Fallback
        local input_val=""
        eggshelltui_input "Enter File Path:" input_val "$init_path"
        if [ $? -eq 0 ]; then
             if [ -n "$BASH_VERSION" ]; then
                 printf -v "$var_name" '%s' "$input_val"
             else
                 read -r "$var_name" <<< "$input_val"
             fi
             return 0
        else
            return 1
        fi
    fi
}

# --- Main Loop Helper ---

eggshelltui_enter_loop() {
    if [[ -z "$CURRENT_SCREEN" ]]; then
        echo "Error: CURRENT_SCREEN not set." >&2
        exit 1
    fi

    while true; do
        # Call the function dynamically
        "screen_$CURRENT_SCREEN"

        # Check if the screen function signaled exit or error?
        # Typically the screen function updates CURRENT_SCREEN or exits.
    done
}

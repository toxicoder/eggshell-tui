# EggshellTUI

EggshellTUI is a lightweight, responsive framework for building interactive Text-based User Interfaces (TUIs) in Bash and Zsh. It leverages `dialog` or `whiptail` to provide a rich set of UI components similar to mobile or web frameworks, but for the terminal.

## Key Features

-   **Responsive Design**: Components automatically resize and reflow based on the terminal window size.
-   **Cross-Shell**: Works on Bash 4+ and Zsh 5+.
-   **Interaction**: Supports keyboard navigation and mouse interaction (where supported by the terminal).
-   **Backend Agnostic**: Automatically detects and uses `dialog` or `whiptail`, with a text-based fallback for basic interactions.

## Installation

Simply source the `eggshelltui.sh` file in your script:

```bash
source eggshelltui.sh
```

Ensure `dialog` is installed on your system for the best experience:
-   Ubuntu/Debian: `sudo apt-get install dialog`
-   macOS: `brew install dialog`

## Components

EggshellTUI provides a suite of standard UI components.

### Menu (`eggshelltui_menu`)
Displays a vertical menu for the user to select an option.

**Usage:**
```bash
eggshelltui_menu "Title" "Option1" "Description1" "Option2" "Description2" ...
```
**Example:**
```bash
eggshelltui_menu "Main Menu" \
    "opt1" "System Info" \
    "opt2" "Network Settings" \
    "exit" "Exit"

case $? in
    1) echo "Selected System Info";;
    2) echo "Selected Network Settings";;
    3) exit 0;;
esac
```

### Input Box (`eggshelltui_input`)
Prompts the user to enter text.

**Usage:**
```bash
eggshelltui_input "Prompt Text" VAR_NAME [InitialValue]
```
**Example:**
```bash
eggshelltui_input "Enter your username:" USERNAME "guest"
if [ $? -eq 0 ]; then
    echo "Hello, $USERNAME"
fi
```

### Message Box (`eggshelltui_msgbox`)
Displays a modal message with an OK button. Useful for alerts or information that requires acknowledgment.

**Usage:**
```bash
eggshelltui_msgbox "Title" "Message text goes here."
```
**Example:**
```bash
eggshelltui_msgbox "Success" "The operation completed successfully."
```

### Yes/No Dialog (`eggshelltui_yesno`)
Asks the user a binary question.

**Usage:**
```bash
eggshelltui_yesno "Title" "Question?"
```
**Example:**
```bash
if eggshelltui_yesno "Confirm" "Are you sure you want to delete this file?"; then
    rm -f file.txt
else
    echo "Cancelled."
fi
```

### Checklist (`eggshelltui_checklist`)
Allows selecting multiple options from a list.

**Usage:**
```bash
eggshelltui_checklist "Title" VAR_NAME "Tag1" "Item1" "status" ...
```
**Example:**
```bash
eggshelltui_checklist "Install Packages" PACKAGES \
    "git" "Git Version Control" "on" \
    "vim" "Vim Editor" "off" \
    "curl" "Curl Utility" "off"

echo "Selected packages: $PACKAGES"
```

### Radiolist (`eggshelltui_radiolist`)
Allows selecting exactly one option from a list (like radio buttons).

**Usage:**
```bash
eggshelltui_radiolist "Title" VAR_NAME "Tag1" "Item1" "status" ...
```
**Example:**
```bash
eggshelltui_radiolist "Choose Difficulty" LEVEL \
    "easy" "Easy Mode" "on" \
    "hard" "Hard Mode" "off"

echo "Level set to: $LEVEL"
```

### Gauge (`eggshelltui_gauge`)
Displays a progress bar.

**Usage:**
```bash
eggshelltui_gauge "Title" "Message" PERCENT
```
**Example:**
```bash
for i in {0..100..10}; do
    eggshelltui_gauge "Installing" "Copying files..." "$i"
    sleep 0.5
done
```

### Text Box (`eggshelltui_textbox`)
Displays the contents of a text file in a scrollable viewer.

**Usage:**
```bash
eggshelltui_textbox "Title" "/path/to/file.txt"
```
**Example:**
```bash
eggshelltui_textbox "License Agreement" "./LICENSE"
```

### Info Box (`eggshelltui_infobox`)
Displays a message without waiting for user input. Often used for "Please wait..." messages before a long operation.

**Usage:**
```bash
eggshelltui_infobox "Title" "Message"
```
**Example:**
```bash
eggshelltui_infobox "Wait" "Calculating data..."
sleep 2
```

## Creating an App

Use the `eggshelltui_enter_loop` helper to manage screen navigation easily.

```bash
#!/bin/bash
source eggshelltui.sh

function screen_main() {
    eggshelltui_menu "App Title" "opt1" "Go to Screen 2" "exit" "Quit"
    case $? in
        1) CURRENT_SCREEN="second";;
        2) exit 0;;
    esac
}

function screen_second() {
    eggshelltui_msgbox "Screen 2" "Welcome to the second screen!"
    CURRENT_SCREEN="main"
}

# Start the app
CURRENT_SCREEN="main"
eggshelltui_enter_loop
```

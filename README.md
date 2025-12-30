# eggshell-tui

The EggshellTUI framework is designed to enable developers to build interactive Text-based User Interfaces (TUIs) for terminal applications that are natively compatible with Bash and Zsh shells.

## Usage

To use EggshellTUI, source the framework script in your application:

```bash
source eggshelltui.sh
```

## Examples

### Basic Menu

Create a simple menu using `eggshelltui_menu`. The function returns the index of the selected option (1-based).

```bash
eggshelltui_menu "Main Menu" "List Items" "Add Item" "Exit"
CHOICE=$?

case $CHOICE in
    1) echo "Selected: List Items";;
    2) echo "Selected: Add Item";;
    3) exit 0;;
esac
```

### Input Box

Capture user input using `eggshelltui_input`. The result is stored in the variable name provided as the second argument.

```bash
eggshelltui_input "Enter your name:" USER_NAME
echo "Hello, $USER_NAME!"
```

### Complete Application

Here is a complete example of an application that uses EggshellTUI to provide both a CLI and a TUI interface.

```bash
#!/bin/bash

source eggshelltui.sh

# 1. Define CLI Functions (The logic)
function cli_list() {
    echo "Listing items..."
    # In a real app, this would list actual data
}

function cli_add() {
    echo "Adding item: $1"
    # In a real app, this would save data
}

# 2. Map Actions to CLI Functions
declare -A ACTIONS
ACTIONS["list"]=cli_list
ACTIONS["add"]=cli_add

# 3. Define TUI Screens
function screen_main() {
    eggshelltui_menu "MyApp Main Menu" "List Items" "Add Item" "Exit"
    case $? in
        1) CURRENT_SCREEN="list";;
        2)
            eggshelltui_input "Enter item name:" ITEM_NAME
            eggshelltui_execute_action "add" "$ITEM_NAME"
            ;;
        3) exit 0;;
    esac
}

function screen_list() {
    # Execute the list action and show output (simplified for example)
    OUTPUT=$(cli_list)
    eggshelltui_infobox "Items" "$OUTPUT"
    CURRENT_SCREEN="main" # Return to main menu
}

# 4. Main Entry Point
if [[ "$1" == "--tui" ]]; then
    # Start TUI Mode
    CURRENT_SCREEN="main"
    eggshelltui_enter_loop
else
    # Start CLI Mode
    case "$1" in
        list) cli_list "${@:2}";;
        add) cli_add "${@:2}";;
        *) echo "Usage: $0 {list|add|--tui}";;
    esac
fi
```

# EggshellTUI

EggshellTUI is a lightweight, responsive framework for building interactive Text-based User Interfaces (TUIs) in Bash and Zsh. It abstracts the complexity of `dialog` and `whiptail`, providing a unified API for creating professional-looking terminal applications.

## Key Features

-   **Responsive Design**: Components automatically resize and reflow based on the terminal window size.
-   **Cross-Shell**: Compatible with Bash 4+ and Zsh 5+.
-   **Backend Agnostic**: Automatically detects and uses `dialog` or `whiptail`, with a text-based fallback for environments without TUI tools.
-   **Rich Component Library**: Includes menus, forms, calendars, gauges, and more.

## Installation

EggshellTUI is a single-file library. To use it, simply source `eggshelltui.sh` in your script:

```bash
source eggshelltui.sh
```

**Dependencies:**
For the full TUI experience, ensure `dialog` or `whiptail` is installed.
-   **Debian/Ubuntu**: `sudo apt-get install dialog`
-   **macOS**: `brew install dialog`
-   **RHEL/CentOS**: `sudo yum install dialog`

## Quick Start

Here is a minimal example to get you started. Save this as `demo.sh` and run it.

```bash
#!/usr/bin/env bash
source eggshelltui.sh

# Best Practice: Register cleanup trap
trap eggshelltui_cleanup EXIT

# 1. Show a welcome message
eggshelltui_msgbox "Welcome" "Welcome to the EggshellTUI Demo!"

# 2. Ask for user input
eggshelltui_input "What is your name?" USER_NAME "Guest"

if [[ $? -eq 0 ]]; then
    # 3. Display result
    eggshelltui_msgbox "Hello" "Nice to meet you, $USER_NAME!"
else
    eggshelltui_msgbox "Cancel" "You cancelled the input."
fi
```

## Components

### 1. Menu (`eggshelltui_menu`)
Displays a vertical menu for selecting an option.

**Usage:**
```bash
eggshelltui_menu "Title" VAR_NAME "Opt1" "Desc1" "Opt2" "Desc2" ...
```

**Example:**
```bash
eggshelltui_menu "Main Menu" SELECTION \
    "opt1" "System Info" \
    "opt2" "Network Settings" \
    "exit" "Exit Application"
```

**Visual Preview:**
```
+---------------------------+
|        Main Menu          |
+---------------------------+
|  opt1    System Info      |
|  opt2    Network Settings |
|  exit    Exit Application |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 2. Input Box (`eggshelltui_input`)
Prompts the user to enter a single line of text.

**Usage:**
```bash
eggshelltui_input "Prompt Text" VAR_NAME [InitialValue]
```

**Example:**
```bash
eggshelltui_input "Enter hostname:" HOSTNAME "localhost"
```

**Visual Preview:**
```
+---------------------------+
|       Enter hostname:     |
+---------------------------+
| +-----------------------+ |
| | localhost             | |
| +-----------------------+ |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 3. Message Box (`eggshelltui_msgbox`)
Displays a modal message with an OK button.

**Usage:**
```bash
eggshelltui_msgbox "Title" "Message text..."
```

**Example:**
```bash
eggshelltui_msgbox "Success" "Operation completed successfully."
```

**Visual Preview:**
```
+---------------------------+
|          Success          |
+---------------------------+
| Operation completed       |
| successfully.             |
|                           |
|          <OK>             |
+---------------------------+
```

---

### 4. Yes/No Dialog (`eggshelltui_yesno`)
Asks a binary question. Returns status `0` for Yes, `1` for No.

**Usage:**
```bash
eggshelltui_yesno "Title" "Question?"
```

**Example:**
```bash
if eggshelltui_yesno "Confirm" "Delete this file?"; then
    rm file.txt
fi
```

**Visual Preview:**
```
+---------------------------+
|          Confirm          |
+---------------------------+
|      Delete this file?    |
|                           |
|      <Yes>      <No>      |
+---------------------------+
```

---

### 5. Info Box (`eggshelltui_infobox`)
Displays a message without waiting for input. Useful for "Please wait" screens.

**Usage:**
```bash
eggshelltui_infobox "Title" "Message..."
```

**Example:**
```bash
eggshelltui_infobox "Processing" "Please wait while we calculate..."
sleep 2
```

**Visual Preview:**
```
+---------------------------+
|        Processing         |
+---------------------------+
| Please wait while we      |
| calculate...              |
+---------------------------+
```

---

### 6. Checklist (`eggshelltui_checklist`)
Allows selecting multiple options.

**Usage:**
```bash
eggshelltui_checklist "Title" VAR_NAME "Tag1" "Item1" "ON/OFF" ...
```

**Example:**
```bash
eggshelltui_checklist "Install Packages" PACKAGES \
    "git" "Git" "on" \
    "vim" "Vim" "off"
```

**Visual Preview:**
```
+---------------------------+
|      Install Packages     |
+---------------------------+
|  [X] git   Git            |
|  [ ] vim   Vim            |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 7. Radiolist (`eggshelltui_radiolist`)
Allows selecting exactly one option from a list.

**Usage:**
```bash
eggshelltui_radiolist "Title" VAR_NAME "Tag1" "Item1" "ON/OFF" ...
```

**Example:**
```bash
eggshelltui_radiolist "Difficulty" LEVEL \
    "easy" "Easy" "on" \
    "hard" "Hard" "off"
```

**Visual Preview:**
```
+---------------------------+
|         Difficulty        |
+---------------------------+
|  (*) easy  Easy           |
|  ( ) hard  Hard           |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 8. Gauge (`eggshelltui_gauge`)
Displays a progress bar.

**Usage:**
```bash
eggshelltui_gauge "Title" "Message" PERCENT
```

**Example:**
```bash
eggshelltui_gauge "Copying" "Copying files..." 50
```

**Visual Preview:**
```
+---------------------------+
|          Copying          |
+---------------------------+
| Copying files...          |
| +-----------------------+ |
| |##########50%          | |
| +-----------------------+ |
+---------------------------+
```

---

### 9. Text Box (`eggshelltui_textbox`)
Displays the contents of a text file in a scrollable viewer.

**Usage:**
```bash
eggshelltui_textbox "Title" FILEPATH
```

**Example:**
```bash
eggshelltui_textbox "License" "./LICENSE"
```

**Visual Preview:**
```
+---------------------------+
|          License          |
+---------------------------+
| MIT License               |
|                           |
| Copyright (c) 2023...     |
| Permission is hereby...   |
|                           |
|          <Exit>           |
+---------------------------+
```

---

### 10. Password Box (`eggshelltui_password`)
Secure input box that hides characters.

**Usage:**
```bash
eggshelltui_password "Prompt" VAR_NAME [InitialValue]
```

**Example:**
```bash
eggshelltui_password "Enter Password:" PASS
```

**Visual Preview:**
```
+---------------------------+
|      Enter Password:      |
+---------------------------+
| +-----------------------+ |
| | ********              | |
| +-----------------------+ |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 11. Form (`eggshelltui_form`)
A complex form with multiple fields.

**Usage:**
```bash
eggshelltui_form "Title" ARRAY_VAR "Label1" "Init1" "Label2" "Init2" ...
```

**Example:**
```bash
eggshelltui_form "User Details" USER_DATA \
    "Name:" "John Doe" \
    "Email:" "john@example.com"
```

**Visual Preview:**
```
+---------------------------+
|        User Details       |
+---------------------------+
| Name:  [ John Doe       ] |
| Email: [ john@example.c ] |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 12. Calendar (`eggshelltui_calendar`)
Date picker.

**Usage:**
```bash
eggshelltui_calendar "Title" VAR_NAME [Day] [Month] [Year]
```

**Example:**
```bash
eggshelltui_calendar "Select Date" DATE_VAL
```

**Visual Preview:**
```
+---------------------------+
|        Select Date        |
+---------------------------+
|      October 2023         |
| Su Mo Tu We Th Fr Sa      |
|  1  2  3  4  5  6  7      |
|  8  9 10 11 12 13 14      |
| ...                       |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 13. Timebox (`eggshelltui_timebox`)
Time picker.

**Usage:**
```bash
eggshelltui_timebox "Title" VAR_NAME [Hour] [Minute] [Second]
```

**Example:**
```bash
eggshelltui_timebox "Select Time" TIME_VAL
```

**Visual Preview:**
```
+---------------------------+
|        Select Time        |
+---------------------------+
|                           |
|      14 : 30 : 00         |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 14. Range (`eggshelltui_range`)
A slider for selecting a value within a range.

**Usage:**
```bash
eggshelltui_range "Title" VAR_NAME Min Max Default
```

**Example:**
```bash
eggshelltui_range "Volume" VOL 0 100 50
```

**Visual Preview:**
```
+---------------------------+
|           Volume          |
+---------------------------+
|      Select value:        |
| +-----------------------+ |
| |----------| 50         | |
| +-----------------------+ |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

---

### 15. File Select (`eggshelltui_fileselect`)
File and directory selection dialog.

**Usage:**
```bash
eggshelltui_fileselect "Title" VAR_NAME [InitialPath]
```

**Example:**
```bash
eggshelltui_fileselect "Open File" FILE_PATH
```

**Visual Preview:**
```
+---------------------------+
|         Open File         |
+---------------------------+
| /home/user/               |
| [..]                      |
| [Documents]               |
| [Downloads]               |
| file.txt                  |
|                           |
|       <OK>   <Cancel>     |
+---------------------------+
```

## Advanced Usage

### Application Loop Helper
For multi-screen applications, EggshellTUI provides a loop helper `eggshelltui_enter_loop`.

1.  Define functions for each screen (e.g., `screen_main`, `screen_settings`).
2.  Set `CURRENT_SCREEN` to the initial screen name (without the `screen_` prefix).
3.  Call `eggshelltui_enter_loop`.
4.  Inside screen functions, update `CURRENT_SCREEN` to navigate or `exit 0` to quit.

```bash
function screen_main() {
    eggshelltui_menu "Main" SEL "opt1" "Go Next" "exit" "Quit"
    case $SEL in
        1) CURRENT_SCREEN="next" ;;
        2) exit 0 ;;
    esac
}

function screen_next() {
    eggshelltui_msgbox "Info" "Next Screen"
    CURRENT_SCREEN="main"
}

CURRENT_SCREEN="main"
eggshelltui_enter_loop
```

### Backend Detection
The framework automatically sets `EGGSHELLTUI_BACKEND` to `dialog`, `whiptail`, or `text`. You can check this variable if you need to implement custom logic based on the available backend.

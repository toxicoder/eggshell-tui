# Technical Design Document: EggshellTUI Framework

## 1. Introduction

### 1.1 Purpose
The EggshellTUI framework is designed to enable developers to build interactive Text-based User Interfaces (TUIs) for terminal applications that are natively compatible with Bash and Zsh shells. It draws inspiration from modern mobile frameworks like Android's templates (e.g., composable UI elements), actions (e.g., intents for triggering behaviors), and deeplinks (e.g., direct navigation to app states via URIs). However, EggshellTUI is optimized for terminal environments, emphasizing keyboard navigation, text rendering, and seamless integration with command-line workflows.

A core principle is that every TUI application must be built atop a fully functional Command-Line Interface (CLI). This ensures:
- **Interface Flexibility**: Users can choose CLI or TUI modes.
- **Scriptability**: The CLI remains automation-friendly for scripts, pipelines, and batch processing.
- **AI Agent Compatibility**: Language models or agents can interact via simple CLI commands without TUI overhead.
- **Portability**: Works across Bash (v4+) and Zsh (v5+), with no external language dependencies beyond standard shell utilities and optional TUI tools like `dialog` or `whiptail`.

### 1.2 Goals
- Provide reusable "templates" for common TUI components (e.g., menus, forms, progress indicators).
- Support "actions" as modular, triggerable functions that map to CLI commands.
- Implement "deeplinks" as command-line arguments for direct navigation to TUI states or CLI executions.
- Ensure zero-cost abstraction: TUI is an optional layer; CLI works independently.
- Optimize for terminal UX: Keyboard-driven, responsive to terminal size, minimal redraws, and error handling for non-interactive modes.
- Encourage best practices: Modular code, error handling, logging, and extensibility.

### 1.3 Scope
- In Scope: Framework core in shell script; CLI/TUI integration; basic templates/actions/deeplinks.
- Out of Scope: Advanced graphics (e.g., beyond text); web integration; non-shell languages.

### 1.4 Assumptions
- Users have `dialog` or `whiptail` installed for TUI rendering (fallback to text-only if absent).
- Apps run in POSIX-compatible environments.
- Developers are familiar with shell scripting.

## 2. Requirements

### 2.1 Functional Requirements
- **CLI Core**: Define subcommands, options, and handlers that execute independently.
- **TUI Mode**: Launch interactive interface with navigation, input, and output rendering.
- **Mode Switching**: Detect mode via flags (e.g., `--tui` for TUI, default to CLI).
- **Templates**: Pre-built UI elements like menus, input forms, checklists, and info boxes.
- **Actions**: Reusable functions that trigger CLI logic, callable from TUI or deeplinks.
- **Deeplinks**: URI-like arguments (e.g., `app://screen/action?param=value`) parsed to navigate or execute.
- **Scripting Support**: CLI outputs in machine-readable formats (e.g., JSON) via flags like `--json`.
- **AI Agent Integration**: CLI commands are simple, idempotent, and support piping/stdin.
- **Error Handling**: Graceful degradation (e.g., fall back to CLI if TUI tools missing).

### 2.2 Non-Functional Requirements
- **Performance**: Low overhead; no loops/redraws unless interactive.
- **Compatibility**: Bash/Zsh; tested on Linux/macOS.
- **Security**: Sanitize inputs; avoid eval where possible.
- **Extensibility**: Hooks for custom templates/actions.
- **Documentation**: Inline comments; example apps.

### 2.3 Constraints
- No external dependencies beyond `dialog`/`whiptail` for TUI.
- Keep framework lightweight (<500 LOC).

## 3. Architecture

### 3.1 High-Level Overview
EggshellTUI is a sourced shell library (`eggshelltui.sh`) that provides functions for CLI and TUI construction. Applications are single shell scripts that:
1. Source the framework.
2. Define CLI handlers (functions).
3. Map handlers to actions.
4. Define TUI templates and navigation.
5. Parse arguments to decide mode/deeplink.

**Layered Structure**:
- **CLI Layer**: Pure functions/subcommands (e.g., using `case` for parsing).
- **Action Layer**: Wrappers that bind CLI functions to triggers (e.g., events or deeplinks).
- **TUI Layer**: Rendering and event loop using `dialog`; maps user input to actions.
- **Deeplink Parser**: Converts arguments to action calls.

In non-interactive modes (e.g., scripting), only CLI executes. In TUI mode, an event loop handles navigation.

**Flow Diagram** (Text Representation):
```
User Input (Args/Stdin) --> Parser (Mode/Deeplink) 
                            |
                            v
If CLI Mode: Execute CLI Handler --> Output (Text/JSON)
If TUI Mode: Enter Event Loop --> Render Template --> Capture Input --> Trigger Action --> Update/Exit
```

### 3.2 Key Components
- **Framework File**: `eggshelltui.sh` – Sourced by apps.
- **App Script**: `myapp.sh` – Defines app-specific logic.
- **Runtime Dependencies**: `dialog` (preferred) or `whiptail` for dialogs; falls back to `read`/`echo` if missing.

## 4. Detailed Design

### 4.1 CLI Layer
The CLI is the foundation: a set of functions that perform core operations. Apps define these as standalone functions.

- **Subcommand Parsing**: Use `case` on `$1` for top-level commands.
- **Options**: Parse with `getopts` or shift-loop.
- **Output Modes**: Support `--json` for structured output.
- **Example Structure**:
  ```bash
  # In myapp.sh
  function cli_list_items() {
      # Logic to list items
      if [ "$1" == "--json" ]; then
          echo '{"items": ["item1", "item2"]}'
      else
          echo "item1"
          echo "item2"
      fi
  }
  ```

### 4.2 Action Layer
Actions are named, callable units that wrap CLI functions. They can be triggered by TUI events or deeplinks.

- **Definition**: Associative array mapping action names to functions.
- **Execution**: `eggshelltui_execute_action "action_name" args...`
- **Example**:
  ```bash
  declare -A ACTIONS
  ACTIONS["list"]=cli_list_items
  ACTIONS["add"]=cli_add_item
  ```

### 4.3 TUI Layer
Uses `dialog` for rendering. Framework provides template functions.

- **Detection**: If `command -v dialog >/dev/null`, use it; else fallback.
- **Event Loop**: While loop that renders current screen, captures choice, triggers action, updates state.
- **State Management**: Global variables for current screen, params.
- **Templates** (Inspired by Android composables):
  - `eggshelltui_menu`: Renders a menu with choices.
  - `eggshelltui_input`: Text input box.
  - `eggshelltui_checklist`: Multi-select.
  - `eggshelltui_progress`: Gauge for long ops.
  - `eggshelltui_infobox`: Display text.

  Example Usage:
  ```bash
  eggshelltui_menu "Main Menu" "List Items" "Add Item" "Exit"
  CHOICE=$?
  case $CHOICE in
      1) eggshelltui_execute_action "list" ;;
      2) eggshelltui_execute_action "add" ;;
  esac
  ```

- **Navigation**: Screens as functions (e.g., `screen_main`, `screen_details`). Deeplinks set initial screen.

- **UX Optimizations**:
  - Auto-resize based on `$LINES`/`$COLUMNS`.
  - Keyboard shortcuts (e.g., arrow keys, Enter).
  - Color themes via `dialog --colors`.
  - Non-blocking for background tasks (use subshells).

### 4.4 Deeplink Layer
Deeplinks are strings like `tui://screen/action?param=value` passed as arguments.

- **Parser**: Function `eggshelltui_parse_deeplink` that splits on `/`, `?`, `&`.
- **Integration**: If arg starts with `tui://` or `--deeplink=`, parse and set initial state/action.
- **CLI Fallback**: If deeplink specifies an action without TUI, execute in CLI mode.
- **Example**: `./myapp.sh tui://main/list?filter=active` → Navigate to main screen, trigger "list" action with param.

### 4.5 Mode Detection and Entry
- **Parsing**:
  ```bash
  if [[ "$1" == "--tui" || "$1" =~ ^tui:// ]]; then
      MODE="tui"
      eggshelltui_parse_deeplink "$1"
  else
      MODE="cli"
  fi
  ```
- **TUI Entry**: `eggshelltui_enter_loop` – Calls initial screen, handles loop.
- **Exit Handling**: Trap SIGINT for cleanup.

### 4.6 Error Handling and Logging
- **Fallback**: If TUI fails (e.g., no dialog), switch to CLI with warning.
- **Logging**: Optional `--log=file` to append outputs.
- **Validation**: Sanitize inputs with parameter expansion.

### 4.7 Extensibility
- **Hooks**: Pre/post action hooks (e.g., `pre_list` function).
- **Custom Templates**: Apps can override framework functions.
- **Theming**: Export vars like `EGGSHELLTUI_COLOR_PRIMARY`.

## 5. Implementation Plan

### 5.1 Framework Code Skeleton (`eggshelltui.sh`)
```bash
#!/bin/bash  # Shebang for Bash; Zsh compatible

# Template Functions
function eggshelltui_menu() {
    local title="$1"; shift
    dialog --menu "$title" 0 0 0 "$@" 2>&1 >/dev/tty
    return $?
}

# ... other templates ...

# Action Executor
function eggshelltui_execute_action() {
    local action="$1"; shift
    if [[ -n "${ACTIONS[$action]}" ]]; then
        ${ACTIONS[$action]} "$@"
    else
        echo "Unknown action: $action" >&2
        exit 1
    fi
}

# Deeplink Parser
function eggshelltui_parse_deeplink() {
    local dl="$1"
    # Parse logic: split on /, ?, &
    INITIAL_SCREEN="${dl#*://}"  # e.g., main/list
    # ... set params ...
}

# Event Loop
function eggshelltui_enter_loop() {
    while true; do
        "screen_${CURRENT_SCREEN}"  # Dynamic call
        # Handle choice, update CURRENT_SCREEN or break
    done
}

# Fallback Detector
if ! command -v dialog >/dev/null; then
    function eggshelltui_menu() {  # Text fallback
        echo "$1"
        select choice in "$@"; do echo $REPLY; break; done
    }
fi
```

### 5.2 Example App (`myapp.sh`)
```bash
#!/bin/bash

source eggshelltui.sh

# Define CLI Functions
function cli_list() { echo "Listing..."; }
function cli_add() { echo "Adding $1"; }

# Map Actions
declare -A ACTIONS
ACTIONS["list"]=cli_list
ACTIONS["add"]=cli_add

# Define Screens
function screen_main() {
    eggshelltui_menu "MyApp" "List" "Add" "Exit"
    case $? in
        1) CURRENT_SCREEN="list";;
        2) eggshelltui_input "Enter name:" NAME; eggshelltui_execute_action "add" "$NAME";;
        3) exit 0;;
    esac
}

# Main Entry
if [[ "$1" == "--tui" ]]; then
    CURRENT_SCREEN="main"
    eggshelltui_enter_loop
else
    # CLI parsing
    case "$1" in
        list) cli_list "${@:2}";;
        add) cli_add "${@:2}";;
    esac
fi
```

### 5.3 Testing
- Unit: Test functions individually.
- Integration: Run in Bash/Zsh, with/without dialog.
- Scenarios: CLI scripting (`myapp.sh list | grep`), TUI navigation, deeplinks.

## 6. Risks and Mitigations
- **Dependency Issues**: Fallback to basic read/echo.
- **Zsh Compatibility**: Use POSIX syntax; test quirks like array handling.
- **Performance in Loops**: Limit redraws; use sleep wisely.
- **Security**: Escape all user inputs in dialogs.

## 7. Future Enhancements
- Support for more tools (e.g., `fzf` for fuzzy search).
- Multi-window simulation.
- Integration with tmux for split views.

## 8. References
- Android Developer Docs (for inspiration).
- `dialog` man pages.
- Bash/Zsh scripting best practices.
- GitHub Repository: toxicoder/eggshell-tui

# Implementation Plan: EggshellTUI Framework

This document outlines the detailed tasks for implementing the EggshellTUI framework based on the [Technical Design Document](TECHNICAL_DESIGN_DOCUMENT.md).

## Phase 1: Project Setup and Core Structure

- [ ] **Initialize Project Files**
    - Create `eggshelltui.sh` (The framework library).
    - Create `myapp.sh` (The example application/consumer).
    - Ensure both are executable (`chmod +x`).

- [ ] **Implement Core Action Layer in `eggshelltui.sh`**
    - Define `eggshelltui_execute_action` function.
    - Logic: Look up action name in global `ACTIONS` associative array.
    - Execute the corresponding function with arguments.
    - Error handling: Print error to stderr and exit if action not found.

- [ ] **Implement Backend Detection**
    - Create `eggshelltui_detect_backend` function.
    - Logic: Check `command -v dialog`, then `command -v whiptail`.
    - Set global `EGGSHELLTUI_BACKEND` to `dialog`, `whiptail`, or `text` (fallback).

## Phase 2: TUI Components (Templates)

- [ ] **Implement `eggshelltui_menu`**
    - Arguments: Title, prompt, and list of options (pairs of "tag" "item" usually, or just items). *Design doc says "Title" "Option1" "Option2"*. We need to standardize how options are passed (array or args).
    - **Dialog/Whiptail**: Construct command for `--menu`. Handle output to stderr (dialog default) or stdout swap.
    - **Fallback**: Use `select` loop or simple numbered list with `read`.

- [ ] **Implement `eggshelltui_input`**
    - Arguments: Title, variable name to store result.
    - **Dialog/Whiptail**: Use `--inputbox`. Capture output.
    - **Fallback**: Use `read -p`.
    - **Output**: Store result in the variable provided by name (using `eval` or `printf -v`).

- [ ] **Implement `eggshelltui_msgbox` / `eggshelltui_infobox`**
    - Arguments: Title, Message.
    - **Dialog/Whiptail**: Use `--msgbox`.
    - **Fallback**: `echo` message and wait for enter (`read`).

- [ ] **Implement `eggshelltui_checklist`** (Priority: Medium)
    - Arguments: Title, list of options.
    - **Dialog/Whiptail**: Use `--checklist`.
    - **Fallback**: Loop with `read` to toggle selections.

## Phase 3: Deeplinks and Event Loop

- [ ] **Implement `eggshelltui_parse_deeplink`**
    - Arguments: URI string (e.g., `tui://screen/action?param=value`).
    - Logic:
        - Extract `screen` -> Set `CURRENT_SCREEN`.
        - Extract `action` -> (Optional) Schedule immediate action execution.
        - Extract `params` -> Parse query string into variables.

- [ ] **Implement `eggshelltui_enter_loop`**
    - Logic:
        - `while true` loop.
        - check `CURRENT_SCREEN` variable.
        - Execute function `screen_${CURRENT_SCREEN}`.
        - Handle return codes or state changes.
        - Trap `SIGINT` for clean exit.

## Phase 4: Example Application (`myapp.sh`)

- [ ] **Define CLI Logic**
    - Create pure functions: `cli_list_items`, `cli_add_item`.
    - These should echo text or JSON.

- [ ] **Define TUI Screens**
    - `screen_main`: Calls `eggshelltui_menu` with Main Menu options. Switches `CURRENT_SCREEN`.
    - `screen_add`: Calls `eggshelltui_input`, then triggers `cli_add_item` action.
    - `screen_list`: Calls `cli_list_items`, shows result in `eggshelltui_msgbox`.

- [ ] **Wiring and Entry Point**
    - Source `eggshelltui.sh`.
    - Declare `ACTIONS` map mapping strings to CLI functions.
    - Parse arguments:
        - If `--tui` or `tui://`: Set mode to TUI, call `eggshelltui_enter_loop`.
        - Else: Execute CLI command based on `$1`.

## Phase 5: Testing and Polish

- [ ] **Verify CLI Mode**
    - Run `./myapp.sh list`.
    - Run `./myapp.sh add "Item Name"`.

- [ ] **Verify TUI Mode**
    - Run `./myapp.sh --tui`.
    - Navigate menus, add item, list items.

- [ ] **Verify Deeplinks**
    - Run `./myapp.sh tui://add`.

- [ ] **Verify Fallback**
    - Force `EGGSHELLTUI_BACKEND="text"` and verify flow works without `dialog`.

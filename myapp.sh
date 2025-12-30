#!/bin/bash

# Example Application for EggshellTUI
# This script demonstrates how to build an app using the framework.

# Source the framework
source ./eggshelltui.sh

# Main entry point
echo "MyApp initialized."
eggshelltui_detect_backend
echo "Running with backend: $EGGSHELLTUI_BACKEND"

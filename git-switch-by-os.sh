#!/bin/bash

# Script to switch git branch based on detected OS
# Allowed mappings: "Ubuntu": main, "MacOS": MacOS

OS=$(uname -s)
BRANCH_TO_SWITCH=""

case "$OS" in
    Linux*)
        if [[ "$(grep -E 'Ubuntu' /etc/os-release 2>/dev/null)" ]]; then
            echo "Detected OS: Ubuntu. Switching to main branch..."
            BRANCH_TO_SWITCH="main"
        else
            echo "Detected Linux, but not explicitly recognized as Ubuntu. Please check the script logic."
            exit 1
        fi
        ;;
    Darwin*) # macOS uses Darwin kernel
        echo "Detected OS: MacOS. Switching to MacOS branch..."
        BRANCH_TO_SWITCH="MacOS"
        ;;
    * )
        echo "Unsupported operating system detected: $OS. Please check the script logic."
        exit 1
        ;;
esac

# Check if the target branch exists before switching
if git show-ref --verify --quiet refs/heads/"$BRANCH_TO_SWITCH"; then
    git switch "$BRANCH_TO_SWITCH"
    echo "Successfully switched to the '$BRANCH_TO_SWITCH' branch."
else
    echo "Error: The required branch '$BRANCH_TO_SWITCH' does not exist in this repository. Please create it first."
    exit 1
fi
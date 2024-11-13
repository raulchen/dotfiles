#!/bin/bash
# Script to find the project root based on specific files or directories

# Define the files or directories that signify the project root
special_paths=(".git" "Makefile" "package.json")

# Start at the current directory
current_path="$1"

# Traverse up to find the project root
while [[ "$current_path" != "/" ]]; do
    for special_path in "${special_paths[@]}"; do
        if [[ -e "$current_path/$special_path" ]]; then
            echo "$current_path"
            exit 0
        fi
    done
    # Move up one directory
    current_path=$(dirname "$current_path")
done

# If no project root is found, default to the initial directory
echo "$1"

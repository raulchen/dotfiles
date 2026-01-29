#!/bin/bash
# Script to find the project root based on specific files or directories

# Files or directories that signify a project root.
special_paths=(".git" "package.json" "Cargo.toml" "go.mod" "pyproject.toml" "pom.xml" "build.gradle" "build.gradle.kts")

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

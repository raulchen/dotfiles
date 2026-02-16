#!/bin/bash
# Script to find the project root based on specific files or directories

# Files or directories that signify a project root.
special_paths=(".git" "package.json" "Cargo.toml" "go.mod" "pyproject.toml" "pom.xml" "build.gradle" "build.gradle.kts")

# Start at the absolute path of the input (default to current directory)
target="${1:-.}"
current_path=$(realpath "$target" 2>/dev/null || echo "$target")

# Traverse up to find the project root
while true; do
    for special_path in "${special_paths[@]}"; do
        if [[ -e "$current_path/$special_path" ]]; then
            echo "$current_path"
            exit 0
        fi
    done

    # Stop if we've reached the root directory
    [[ "$current_path" == "/" ]] && break

    # Move up one directory
    current_path=$(dirname "$current_path")
done

# If no project root is found, return the absolute path of the initial target
realpath "$target" 2>/dev/null || echo "$target"

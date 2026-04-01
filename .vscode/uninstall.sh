#!/bin/bash
#
# ECC VS Code Uninstaller
# Uninstalls Everything Claude Code workflows from a VS Code project.
#
# Usage:
#   cd /path/to/project/.vscode
#   ./uninstall.sh
#
#   Or from the project root:
#   .vscode/uninstall.sh
#

set -euo pipefail

# Resolve the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# VS Code directory name
VSCODE_DIR=".vscode"

resolve_path() {
    python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

is_valid_manifest_entry() {
    local file_path="$1"

    case "$file_path" in
        ""|/*|~*|*/../*|../*|*/..|..)
            return 1
            ;;
    esac

    return 0
}

# Main uninstall function
do_uninstall() {
    local target_dir

    # Use SCRIPT_DIR as the base for finding the .vscode directory,
    # which works correctly whether the script is called from within
    # .vscode/ or from the project root.
    local script_parent_name="$(basename "$SCRIPT_DIR")"
    local vscode_full_path

    if [ "$script_parent_name" = "$VSCODE_DIR" ]; then
        # Script lives inside .vscode/ — use that directory directly
        vscode_full_path="$SCRIPT_DIR"
    else
        # Script lives at the project root — look for .vscode/ in the same dir
        vscode_full_path="$SCRIPT_DIR/$VSCODE_DIR"
    fi

    # Allow an explicit path override via positional argument
    if [ "$#" -ge 1 ]; then
        if [ "$1" = "~" ] || [ "$1" = "$HOME" ]; then
            vscode_full_path="$HOME/$VSCODE_DIR"
        fi
    fi

    echo "ECC VS Code Uninstaller"
    echo "======================="
    echo ""
    echo "Target:  $vscode_full_path/"
    echo ""

    if [ ! -d "$vscode_full_path" ]; then
        echo "Error: $VSCODE_DIR directory not found at $vscode_full_path"
        exit 1
    fi

    vscode_root_resolved="$(resolve_path "$vscode_full_path")"

    # Manifest file path
    MANIFEST="$vscode_full_path/.ecc-manifest"

    if [ ! -f "$MANIFEST" ]; then
        echo "Warning: No manifest file found (.ecc-manifest)"
        echo ""
        echo "This could mean:"
        echo "  1. ECC was installed with an older version without manifest support"
        echo "  2. The manifest file was manually deleted"
        echo ""
        read -p "Do you want to remove the entire $VSCODE_DIR directory? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Uninstall cancelled."
            exit 0
        fi
        rm -rf "$vscode_full_path"
        echo "Uninstall complete!"
        echo ""
        echo "Removed: $vscode_full_path/"
        exit 0
    fi

    echo "Found manifest file - will only remove files installed by ECC"
    echo ""
    read -p "Are you sure you want to uninstall ECC from $VSCODE_DIR? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    # Counters
    removed=0
    skipped=0

    # Read manifest and remove files
    while IFS= read -r file_path; do
        [ -z "$file_path" ] && continue

        if ! is_valid_manifest_entry "$file_path"; then
            echo "Skipped: $file_path (invalid manifest entry)"
            skipped=$((skipped + 1))
            continue
        fi

        full_path="$vscode_full_path/$file_path"

        # Security check: ensure the path resolves inside the target directory.
        relative="$(python3 -c 'import os,sys; print(os.path.relpath(os.path.abspath(sys.argv[1]), sys.argv[2]))' "$full_path" "$vscode_root_resolved")"
        case "$relative" in
            ../*|..)
                echo "Skipped: $file_path (outside target directory)"
                skipped=$((skipped + 1))
                continue
                ;;
        esac

        if [ -L "$full_path" ] || [ -f "$full_path" ]; then
            rm -f "$full_path"
            echo "Removed: $file_path"
            removed=$((removed + 1))
        elif [ -d "$full_path" ]; then
            # Only remove directory if it's empty
            if [ -z "$(ls -A "$full_path" 2>/dev/null)" ]; then
                rmdir "$full_path" 2>/dev/null || true
                if [ ! -d "$full_path" ]; then
                    echo "Removed: $file_path/"
                    removed=$((removed + 1))
                fi
            else
                echo "Skipped: $file_path/ (not empty - contains user files)"
                skipped=$((skipped + 1))
            fi
        else
            skipped=$((skipped + 1))
        fi
    done < "$MANIFEST"

    while IFS= read -r empty_dir; do
        [ "$empty_dir" = "$vscode_full_path" ] && continue
        relative_dir="${empty_dir#$vscode_full_path/}"
        rmdir "$empty_dir" 2>/dev/null || true
        if [ ! -d "$empty_dir" ]; then
            echo "Removed: $relative_dir/"
            removed=$((removed + 1))
        fi
    done < <(find "$vscode_full_path" -depth -type d -empty 2>/dev/null | sort -r)

    # Try to remove the main vscode directory if it's empty
    if [ -d "$vscode_full_path" ] && [ -z "$(ls -A "$vscode_full_path" 2>/dev/null)" ]; then
        rmdir "$vscode_full_path" 2>/dev/null || true
        if [ ! -d "$vscode_full_path" ]; then
            echo "Removed: $VSCODE_DIR/"
            removed=$((removed + 1))
        fi
    fi

    echo ""
    echo "Uninstall complete!"
    echo ""
    echo "Summary:"
    echo "  Removed: $removed items"
    echo "  Skipped: $skipped items (not found or user-modified)"
    echo ""
    if [ -d "$vscode_full_path" ]; then
        echo "Note: $VSCODE_DIR directory still exists (contains user-added files)"
    fi
}

# Execute uninstall
do_uninstall "$@"

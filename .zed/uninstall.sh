#!/bin/bash
#
# ECC Zed Uninstaller
# Uninstalls Everything Claude Code workflows from a Zed project.
#
# Usage:
#   cd /path/to/project/.zed
#   ./uninstall.sh
#
#   Or from the project root:
#   .zed/uninstall.sh
#

set -euo pipefail

# Resolve the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Zed directory name
ZED_DIR=".zed"

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
    # Use SCRIPT_DIR as the base for finding the .zed directory,
    # which works correctly whether the script is called from within
    # .zed/ or from the project root.
    local script_parent_name="$(basename "$SCRIPT_DIR")"
    local zed_full_path

    if [ "$script_parent_name" = "$ZED_DIR" ]; then
        # Script lives inside .zed/ — use that directory directly
        zed_full_path="$SCRIPT_DIR"
    else
        # Script lives at the project root — look for .zed/ in the same dir
        zed_full_path="$SCRIPT_DIR/$ZED_DIR"
    fi

    # Allow an explicit path override via positional argument
    if [ "$#" -ge 1 ]; then
        if [ "$1" = "~" ] || [ "$1" = "$HOME" ]; then
            zed_full_path="$HOME/$ZED_DIR"
        fi
    fi

    echo "ECC Zed Uninstaller"
    echo "==================="
    echo ""
    echo "Target:  $zed_full_path/"
    echo ""

    if [ ! -d "$zed_full_path" ]; then
        echo "Error: $ZED_DIR directory not found at $zed_full_path"
        exit 1
    fi

    zed_root_resolved="$(resolve_path "$zed_full_path")"

    # Manifest file path
    MANIFEST="$zed_full_path/.ecc-manifest"

    if [ ! -f "$MANIFEST" ]; then
        echo "Warning: No manifest file found (.ecc-manifest)"
        echo ""
        echo "This could mean:"
        echo "  1. ECC was installed with an older version without manifest support"
        echo "  2. The manifest file was manually deleted"
        echo ""
        read -p "Do you want to remove the entire $ZED_DIR directory? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Uninstall cancelled."
            exit 0
        fi
        rm -rf "$zed_full_path"
        echo "Uninstall complete!"
        echo ""
        echo "Removed: $zed_full_path/"
        exit 0
    fi

    echo "Found manifest file - will only remove files installed by ECC"
    echo ""
    read -p "Are you sure you want to uninstall ECC from $ZED_DIR? (y/N) " -n 1 -r
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

        full_path="$zed_full_path/$file_path"

        # Security check: ensure the path resolves inside the target directory.
        relative="$(python3 -c 'import os,sys; print(os.path.relpath(os.path.abspath(sys.argv[1]), sys.argv[2]))' "$full_path" "$zed_root_resolved")"
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
        [ "$empty_dir" = "$zed_full_path" ] && continue
        relative_dir="${empty_dir#$zed_full_path/}"
        rmdir "$empty_dir" 2>/dev/null || true
        if [ ! -d "$empty_dir" ]; then
            echo "Removed: $relative_dir/"
            removed=$((removed + 1))
        fi
    done < <(find "$zed_full_path" -depth -type d -empty 2>/dev/null | sort -r)

    # Try to remove the main zed directory if it's empty
    if [ -d "$zed_full_path" ] && [ -z "$(ls -A "$zed_full_path" 2>/dev/null)" ]; then
        rmdir "$zed_full_path" 2>/dev/null || true
        if [ ! -d "$zed_full_path" ]; then
            echo "Removed: $ZED_DIR/"
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
    if [ -d "$zed_full_path" ]; then
        echo "Note: $ZED_DIR directory still exists (contains user-added files)"
    fi
}

# Execute uninstall
do_uninstall "$@"

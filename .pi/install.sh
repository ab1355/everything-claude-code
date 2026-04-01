#!/bin/bash
#
# ECC Pi.dev Installer
# Installs Everything Claude Code workflows into a pi.dev project.
#
# Usage:
#   ./install.sh              # Install to current directory
#   ./install.sh ~            # Install globally to ~/.pi/
#
# Pi.dev uses skills in .pi/skills/ and settings in .pi/settings.json.
# See https://pi.dev for more information.
#

set -euo pipefail

# When globs match nothing, expand to empty list instead of the literal pattern
shopt -s nullglob

# Resolve the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Locate the ECC repo root by walking up from SCRIPT_DIR to find the marker
# file (VERSION). This keeps the script working even when it has been copied
# into a target project's .pi/ directory.
find_repo_root() {
    local dir="$(dirname "$SCRIPT_DIR")"
    # First try the parent of SCRIPT_DIR (original layout: .pi/ lives in repo root)
    if [ -f "$dir/VERSION" ] && [ -d "$dir/commands" ] && [ -d "$dir/agents" ]; then
        echo "$dir"
        return 0
    fi
    echo ""
    return 1
}

REPO_ROOT="$(find_repo_root)"
if [ -z "$REPO_ROOT" ]; then
    echo "Error: Cannot locate the ECC repository root."
    echo "This script must be run from within the ECC repository's .pi/ directory."
    exit 1
fi

# Pi.dev directory name
PI_DIR=".pi"

ensure_manifest_entry() {
    local manifest="$1"
    local entry="$2"

    touch "$manifest"
    if ! grep -Fqx "$entry" "$manifest"; then
        echo "$entry" >> "$manifest"
    fi
}

manifest_has_entry() {
    local manifest="$1"
    local entry="$2"

    [ -f "$manifest" ] && grep -Fqx "$entry" "$manifest"
}

copy_managed_file() {
    local source_path="$1"
    local target_path="$2"
    local manifest="$3"
    local manifest_entry="$4"
    local make_executable="${5:-0}"

    local already_managed=0
    if manifest_has_entry "$manifest" "$manifest_entry"; then
        already_managed=1
    fi

    if [ -f "$target_path" ]; then
        if [ "$already_managed" -eq 1 ]; then
            ensure_manifest_entry "$manifest" "$manifest_entry"
        fi
        return 1
    fi

    cp "$source_path" "$target_path"
    if [ "$make_executable" -eq 1 ]; then
        chmod +x "$target_path"
    fi
    ensure_manifest_entry "$manifest" "$manifest_entry"
    return 0
}

# Install function
do_install() {
    local target_dir="$PWD"

    # Check if ~ was specified (or expanded to $HOME)
    if [ "$#" -ge 1 ]; then
        if [ "$1" = "~" ] || [ "$1" = "$HOME" ]; then
            target_dir="$HOME"
        fi
    fi

    # Check if we're already inside a .pi directory
    local current_dir_name="$(basename "$target_dir")"
    local pi_full_path

    if [ "$current_dir_name" = "$PI_DIR" ]; then
        # Already inside the pi directory, use it directly
        pi_full_path="$target_dir"
    else
        # Normal case: append PI_DIR to target_dir
        pi_full_path="$target_dir/$PI_DIR"
    fi

    echo "ECC Pi.dev Installer"
    echo "===================="
    echo ""
    echo "Source:  $REPO_ROOT"
    echo "Target:  $pi_full_path/"
    echo ""

    # Create the .pi directory and skills subdirectory
    mkdir -p "$pi_full_path/skills"

    # Manifest file to track installed files
    MANIFEST="$pi_full_path/.ecc-manifest"
    touch "$MANIFEST"

    # Counters for summary
    skills=0
    other=0

    # Copy skills from repo root into .pi/skills/
    # Pi.dev auto-discovers skills from .pi/skills/
    if [ -d "$REPO_ROOT/skills" ]; then
        for d in "$REPO_ROOT/skills"/*/; do
            [ -d "$d" ] || continue
            skill_name="$(basename "$d")"
            target_skill_dir="$pi_full_path/skills/$skill_name"
            skill_copied=0

            while IFS= read -r source_file; do
                relative_path="${source_file#$d}"
                target_path="$target_skill_dir/$relative_path"

                mkdir -p "$(dirname "$target_path")"
                if copy_managed_file "$source_file" "$target_path" "$MANIFEST" "skills/$skill_name/$relative_path"; then
                    skill_copied=1
                fi
            done < <(find "$d" -type f | sort)

            if [ "$skill_copied" -eq 1 ]; then
                skills=$((skills + 1))
            fi
        done
    fi

    # Copy settings.json from this directory
    if [ -f "$SCRIPT_DIR/settings.json" ]; then
        if copy_managed_file "$SCRIPT_DIR/settings.json" "$pi_full_path/settings.json" "$MANIFEST" "settings.json"; then
            other=$((other + 1))
        fi
    fi

    # Copy AGENTS.md and CLAUDE.md into .pi/ (pi uses these as context files via settings.json)
    for context_file in "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/CLAUDE.md"; do
        if [ -f "$context_file" ]; then
            local_name=$(basename "$context_file")
            if copy_managed_file "$context_file" "$pi_full_path/$local_name" "$MANIFEST" "$local_name"; then
                other=$((other + 1))
            fi
        fi
    done

    # Copy README files from this directory
    for readme_file in "$SCRIPT_DIR/README.md"; do
        if [ -f "$readme_file" ]; then
            local_name=$(basename "$readme_file")
            target_path="$pi_full_path/$local_name"
            if copy_managed_file "$readme_file" "$target_path" "$MANIFEST" "$local_name"; then
                other=$((other + 1))
            fi
        fi
    done

    # Copy install and uninstall scripts
    for script_file in "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/uninstall.sh"; do
        if [ -f "$script_file" ]; then
            local_name=$(basename "$script_file")
            target_path="$pi_full_path/$local_name"
            if copy_managed_file "$script_file" "$target_path" "$MANIFEST" "$local_name" 1; then
                other=$((other + 1))
            fi
        fi
    done

    # Add manifest file itself to manifest
    ensure_manifest_entry "$MANIFEST" ".ecc-manifest"

    # Installation summary
    echo "Installation complete!"
    echo ""
    echo "Components installed:"
    echo "  Skills:    $skills (in $PI_DIR/skills/)"
    echo "  Other:     $other (settings, README, context files)"
    echo ""
    echo "Directory:   $PI_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Install pi.dev: npm install -g @mariozechner/pi-coding-agent"
    echo "  2. Run pi in your project directory"
    echo "  3. Pi will auto-discover skills from $PI_DIR/skills/"
    echo "  4. Use /skill <name> to activate a skill in pi"
    echo "  5. Enjoy the ECC workflows!"
    echo ""
    echo "To uninstall later:"
    echo "  .pi/uninstall.sh"
}

# Main logic
do_install "$@"

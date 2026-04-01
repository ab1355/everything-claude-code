#!/bin/bash
#
# ECC Zed Installer
# Installs Everything Claude Code workflows into a Zed project.
#
# Usage:
#   ./install.sh              # Install to current directory
#   ./install.sh ~            # Install globally to ~/.zed/
#

set -euo pipefail

# When globs match nothing, expand to empty list instead of the literal pattern
shopt -s nullglob

# Resolve the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Locate the ECC repo root by walking up from SCRIPT_DIR to find the marker
# file (VERSION). This keeps the script working even when it has been copied
# into a target project's .zed/ directory.
find_repo_root() {
    local dir="$(dirname "$SCRIPT_DIR")"
    # First try the parent of SCRIPT_DIR (original layout: .zed/ lives in repo root)
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
    echo "This script must be run from within the ECC repository's .zed/ directory."
    exit 1
fi

# Zed directory name
ZED_DIR=".zed"

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

    # Check if we're already inside a .zed directory
    local current_dir_name="$(basename "$target_dir")"
    local zed_full_path

    if [ "$current_dir_name" = "$ZED_DIR" ]; then
        # Already inside the zed directory, use it directly
        zed_full_path="$target_dir"
    else
        # Normal case: append ZED_DIR to target_dir
        zed_full_path="$target_dir/$ZED_DIR"
    fi

    echo "ECC Zed Installer"
    echo "================="
    echo ""
    echo "Source:  $REPO_ROOT"
    echo "Target:  $zed_full_path/"
    echo ""

    # Create the .zed directory and subdirectories
    mkdir -p "$zed_full_path"
    SUBDIRS="commands agents skills rules"
    for dir in $SUBDIRS; do
        mkdir -p "$zed_full_path/$dir"
    done

    # Manifest file to track installed files
    MANIFEST="$zed_full_path/.ecc-manifest"
    touch "$MANIFEST"

    # Counters for summary
    commands=0
    agents=0
    skills=0
    rules=0
    other=0

    # Copy commands from repo root
    if [ -d "$REPO_ROOT/commands" ]; then
        for f in "$REPO_ROOT/commands"/*.md; do
            [ -f "$f" ] || continue
            local_name=$(basename "$f")
            target_path="$zed_full_path/commands/$local_name"
            if copy_managed_file "$f" "$target_path" "$MANIFEST" "commands/$local_name"; then
                commands=$((commands + 1))
            fi
        done
    fi

    # Copy agents from repo root
    if [ -d "$REPO_ROOT/agents" ]; then
        for f in "$REPO_ROOT/agents"/*.md; do
            [ -f "$f" ] || continue
            local_name=$(basename "$f")
            target_path="$zed_full_path/agents/$local_name"
            if copy_managed_file "$f" "$target_path" "$MANIFEST" "agents/$local_name"; then
                agents=$((agents + 1))
            fi
        done
    fi

    # Copy skills from repo root
    if [ -d "$REPO_ROOT/skills" ]; then
        for d in "$REPO_ROOT/skills"/*/; do
            [ -d "$d" ] || continue
            skill_name="$(basename "$d")"
            target_skill_dir="$zed_full_path/skills/$skill_name"
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

    # Copy rules from repo root
    if [ -d "$REPO_ROOT/rules" ]; then
        while IFS= read -r rule_file; do
            relative_path="${rule_file#$REPO_ROOT/rules/}"
            target_path="$zed_full_path/rules/$relative_path"

            mkdir -p "$(dirname "$target_path")"
            if copy_managed_file "$rule_file" "$target_path" "$MANIFEST" "rules/$relative_path"; then
                rules=$((rules + 1))
            fi
        done < <(find "$REPO_ROOT/rules" -type f | sort)
    fi

    # Copy AGENTS.md
    if [ -f "$REPO_ROOT/AGENTS.md" ]; then
        if copy_managed_file "$REPO_ROOT/AGENTS.md" "$zed_full_path/AGENTS.md" "$MANIFEST" "AGENTS.md"; then
            other=$((other + 1))
        fi
    fi

    # Copy settings.json from this directory
    if [ -f "$SCRIPT_DIR/settings.json" ]; then
        if copy_managed_file "$SCRIPT_DIR/settings.json" "$zed_full_path/settings.json" "$MANIFEST" "settings.json"; then
            other=$((other + 1))
        fi
    fi

    # Copy README files from this directory
    for readme_file in "$SCRIPT_DIR/README.md" "$SCRIPT_DIR/README.zh-CN.md"; do
        if [ -f "$readme_file" ]; then
            local_name=$(basename "$readme_file")
            target_path="$zed_full_path/$local_name"
            if copy_managed_file "$readme_file" "$target_path" "$MANIFEST" "$local_name"; then
                other=$((other + 1))
            fi
        fi
    done

    # Copy install and uninstall scripts
    for script_file in "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/uninstall.sh"; do
        if [ -f "$script_file" ]; then
            local_name=$(basename "$script_file")
            target_path="$zed_full_path/$local_name"
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
    echo "  Commands:  $commands"
    echo "  Agents:    $agents"
    echo "  Skills:    $skills"
    echo "  Rules:     $rules"
    echo "  Other:     $other (settings, README)"
    echo ""
    echo "Directory:   $ZED_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Open your project in Zed"
    echo "  2. Set ANTHROPIC_API_KEY in your environment"
    echo "  3. Open the AI assistant panel (Ctrl+? or Cmd+?)"
    echo "  4. Use the agent panel to work with ECC workflows"
    echo "  5. Enjoy the ECC workflows!"
    echo ""
    echo "To uninstall later:"
    echo "  .zed/uninstall.sh"
}

# Main logic
do_install "$@"

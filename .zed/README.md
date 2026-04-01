# Everything Claude Code for Zed

Bring Everything Claude Code (ECC) workflows to [Zed](https://zed.dev) — a high-performance code editor built in Rust. This repository provides custom commands, agents, skills, and rules that can be installed into any Zed project with a single command.

## Quick Start

```bash
# Install to current project
.zed/install.sh

# Install globally to ~/.zed/
.zed/install.sh ~
```

The installer uses non-destructive copy — it will not overwrite your existing files.

## What's Included

### Commands

Commands are on-demand workflows available as context for Zed's AI assistant. All commands are reused directly from the project root's `commands/` folder.

### Agents

Agents are specialized AI assistants with specific tool configurations. All agents are reused directly from the project root's `agents/` folder.

### Skills

Skills are on-demand workflows for use with Zed's AI assistant. All skills are reused directly from the project's `skills/` folder.

### Rules

Rules provide always-on context that shapes how the AI assistant works with your code. All rules are reused directly from the project root's `rules/` folder.

### Zed Settings

The installer copies `.zed/settings.json` with recommended AI assistant configuration:

- Configures Anthropic Claude as the default AI model
- Sets the AI assistant version
- Configures tool permissions for safety

## Prerequisites

1. [Zed editor](https://zed.dev) installed
2. An Anthropic API key configured via the Zed settings or environment variable

## Installation

### Local Installation

Install to the current project's `.zed` directory:

```bash
cd /path/to/your/project
.zed/install.sh
```

### Global Installation

Install to your home directory:

```bash
.zed/install.sh ~
```

## Configuration

The `.zed/settings.json` configures Zed's AI assistant to use Anthropic Claude. You can customize the model by editing the settings:

```json
{
  "agent": {
    "default_model": {
      "provider": "anthropic",
      "model": "claude-opus-4-5"
    }
  }
}
```

See [Zed AI Configuration](https://zed.dev/docs/ai) for all available options.

## Uninstall

The uninstaller uses a manifest file (`.ecc-manifest`) to track installed files, ensuring safe removal:

```bash
.zed/uninstall.sh
```

### Uninstall Behavior

- **Safe removal**: Only removes files tracked in the manifest (installed by ECC)
- **User files preserved**: Any files you added manually are kept
- **Non-empty directories**: Directories containing user-added files are skipped
- **Manifest-based**: Requires `.ecc-manifest` file (created during install)

## Project Structure

```
.zed/
├── settings.json       # Zed workspace settings (AI assistant config)
├── install.sh          # Install script
├── uninstall.sh        # Uninstall script
└── README.md           # This file

commands/               # Command files (reused from project root)
agents/                 # Agent files (reused from project root)
skills/                 # Skill files (reused from skills/)
rules/                  # Rule files (reused from project root)
AGENTS.md               # Agent descriptions
```

## Usage

1. Open your project in Zed
2. Set your Anthropic API key (via Zed settings or `ANTHROPIC_API_KEY` env var)
3. Open the AI assistant panel (`Ctrl+?` or `Cmd+?`)
4. Reference agents and skills in your AI assistant conversations
5. Use the `commands/` folder as reference for available workflows

## Recommended Workflow

1. **Start with planning**: Reference `/plan` workflow to break down complex features
2. **Write tests first**: Use `/tdd` workflow before implementing
3. **Review your code**: Use `/code-review` workflow after writing code
4. **Check security**: Use `/code-review` for auth, API endpoints, or sensitive data
5. **Fix build errors**: Use `/build-fix` workflow if there are build errors

## Next Steps

- Open your project in Zed
- Configure your Anthropic API key
- Open the AI assistant panel and start using ECC workflows!

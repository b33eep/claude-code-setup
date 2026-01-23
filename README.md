# Claude Code Setup

[![CI](https://github.com/b33eep/claude-setup/actions/workflows/test.yml/badge.svg)](https://github.com/b33eep/claude-setup/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modular, minimal setup for Claude Code with a clear workflow and persistent memory via Markdown files.

## Core Concept: Document & Clear

**The Problem with `/compact` and `/resume`:**

| Issue | Impact |
|-------|--------|
| Context loss | Important decisions, progress, and details are forgotten |
| Unpredictable | Unclear what gets summarized, what gets dropped |
| Token waste | `/resume` reloads outdated details you no longer need |
| Quality degradation | Compacted context leads to less precise responses |

**The Solution:** External memory via two CLAUDE.md files:

| File | Location | Content | Created by |
|------|----------|---------|------------|
| **Global** | `~/.claude/CLAUDE.md` | Workflow, coding standards, skills | `install.sh` |
| **Project** | `your-project/CLAUDE.md` | Status, tasks, decisions | `/init-project` |

```
┌─────────────────────────────────────────────────────────────┐
│  FIRST TIME: /init-project                                  │
│  - New project → Creates fresh project CLAUDE.md            │
│  - Existing project → Analyzes codebase first               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  SESSION START                                              │
│  1. Global + Project CLAUDE.md load automatically           │
│  2. /catchup → Understand changes + next steps              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  WORK                                                       │
│  - Define tasks in project CLAUDE.md                        │
│  - Implement + Test                                         │
│  - Architecture decisions → Create ADRs                     │
│  - ADRs loaded when relevant (e.g., "Why did we choose X?") │
│  - Monitor context via ccstatusline                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  SESSION END (at context limit)                             │
│  1. /clear-session → Updates project CLAUDE.md, commits     │
│  2. /clear → Fresh context                                  │
└─────────────────────────────────────────────────────────────┘
```

**External Memory:**
- `~/.claude/CLAUDE.md` - Workflow, standards (static, global)
- `project/CLAUDE.md` - Current status, tasks (dynamic, per-project)
- `docs/adr/` - Architecture Decision Records (persistent, versioned)
- Git commits - Progress is saved, not lost

> **Tip:** Enable the Claude Code status line (`/config` → set `ccstatusline` to `true`) to see context usage (e.g., `Ctx: 70.2%`) and know when to `/clear-session`.

## Features

- **Modular Installation** - Choose only the modules you need
- **Custom Modules** - Add your own standards, MCP servers, and skills
- **External Memory** - CLAUDE.md + ADR files as persistent, versioned memory
- **Easy Updates** - Update modules without losing customizations

## Prerequisites

- **macOS** (primary platform)
- **[Homebrew](https://brew.sh/)** (for installing dependencies)
- **[Claude Code](https://claude.ai/code)** CLI installed

## Quick Start

```bash
git clone https://github.com/b33eep/claude-setup.git
cd claude-setup
./install.sh
```

The installer will guide you through selecting:
- MCP servers (PDF Reader, Brave Search, Google Search)
- Skills (Python Standards, TypeScript Standards, Slidev Presentations)

## Installation Options

```bash
./install.sh              # Initial install (interactive wizard)
./install.sh --add        # Add more modules to existing installation
./install.sh --update     # Update all installed modules
./install.sh --list       # Show installed and available modules
./install.sh --help       # Show help
```

## File Structure

### Repository Structure

```
claude-setup/
├── templates/
│   └── base/
│       └── global-CLAUDE.md      # Core: Workflow, conventions
├── mcp/                          # MCP server configurations
│   ├── pdf-reader.json
│   ├── brave-search.json
│   └── google-search.json
├── skills/                       # Skills (coding standards + tools)
│   ├── standards-python/         # Python standards (context skill)
│   ├── standards-typescript/     # TypeScript standards (context skill)
│   └── create-slidev-presentation/
├── commands/                     # Workflow commands (always installed)
│   ├── catchup.md
│   ├── clear-session.md
│   └── init-project.md
└── install.sh
```

### Installed Structure

```
~/.claude/
├── CLAUDE.md              # Generated from base + selected modules
├── commands/              # Workflow commands
├── skills/                # Installed skills
├── installed.json         # Tracks installed modules
└── custom/                # Your custom modules (see below)
    ├── standards/
    ├── mcp/
    └── skills/

~/.claude.json             # MCP servers configuration
```

## Available Modules

### Coding Standards (Context Skills)

Coding standards are now **context skills** that auto-load based on your project's Tech Stack.

| Skill | Auto-loads when Tech Stack contains |
|-------|-------------------------------------|
| `standards-python` | python, fastapi, django, flask, pytest, pydantic, sqlalchemy, celery, poetry, asyncio, aiohttp, httpx |
| `standards-typescript` | typescript, nodejs, react, nextjs, vue, angular, express, nestjs, deno, bun, zod |

**How it works:**
1. Your project `CLAUDE.md` defines: `Tech Stack: Python, FastAPI`
2. At session start, `standards-python` skill auto-loads
3. No manual invocation needed

**Custom standards:** Override with `~/.claude/custom/skills/standards-python/` (see [Custom Skills](#custom-skills))

### MCP Servers

| Server | Description | Requires API Key |
|--------|-------------|------------------|
| `pdf-reader` | Read and analyze PDF documents | No |
| `brave-search` | Web search (2000 free queries/month) | Yes |
| `google-search` | Google Custom Search | Yes |

### Skills

| Skill | Description |
|-------|-------------|
| `create-slidev-presentation` | Create/edit Slidev presentations |

## Custom Modules

Add your own modules without forking the repository.

### Directory Structure

```
~/.claude/custom/
├── mcp/
│   └── internal-api.json # Custom MCP server
└── skills/
    └── my-skill/         # Custom skill
```

### Custom Skills

Custom skills in `~/.claude/custom/skills/` **override** installed skills with the same name.

**Example:** Override Python standards with your company's version:

```
~/.claude/custom/skills/standards-python/
├── SKILL.md              # Your custom Python standards
└── references/
    └── code-review-checklist.md
```

When `standards-python` would load, your custom version is used instead.

**SKILL.md format for context skills:**

```markdown
---
name: standards-python
description: Company Python coding standards
type: context
applies_to: [python, fastapi, django]
---

# Python Standards

Your custom content here...
```

### Custom MCP Format

Create a JSON file in `~/.claude/custom/mcp/`:

```json
{
  "name": "my-server",
  "description": "My custom MCP server",
  "config": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "my-mcp-package"]
  },
  "requiresApiKey": false
}
```

For servers requiring API keys:

```json
{
  "name": "my-api",
  "description": "Server with API key",
  "config": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "my-package"],
    "env": {
      "MY_API_KEY": "{{MY_API_KEY}}"
    }
  },
  "requiresApiKey": true,
  "apiKeyName": "MY_API_KEY",
  "apiKeyPrompt": "Enter your API key",
  "apiKeyInstructions": [
    "1. Go to https://example.com",
    "2. Create an API key"
  ]
}
```

### For Teams/Companies

Create a separate repository with only your custom modules:

```bash
# Company repo structure
my-company-claude-modules/
├── standards/
│   └── company-style.md
├── mcp/
│   └── internal-tools.json
└── skills/
    └── company-templates/
```

Team members clone it to their custom directory:

```bash
git clone git@company.com:team/claude-modules.git ~/.claude/custom
./install.sh --add   # Select company modules
```

Update company modules:

```bash
cd ~/.claude/custom && git pull
./install.sh --update
```

## Commands

| Command | Description |
|---------|-------------|
| `/init-project` | Analyze project, create CLAUDE.md + ADR folder, choose Solo/Team mode |
| `/catchup` | Understand changes + determine next steps (after /clear) |
| `/clear-session` | Update CLAUDE.md status, create ADRs if needed, commit (before /clear) |

### Solo vs Team Mode

When running `/init-project`, you choose how CLAUDE.md is handled:

| Mode | CLAUDE.md | Use Case |
|------|-----------|----------|
| **Solo** | Added to `.gitignore` | Personal workflow, not shared with team |
| **Team** | Tracked in Git | Shared context for all developers |

- **Solo**: Your status, tasks, and notes stay local
- **Team**: Everyone sees project status, decisions, and next steps

`/clear-session` respects this: in Solo mode, only ADRs are committed.

## Configuration

### Disable Auto-Compact

Auto-compaction can cause context loss. Disable it:

1. Open Claude Code settings: `/settings` or `Cmd+,`
2. Go to **Config** tab
3. Set **Auto-compact** to `false`

## Plugins (Optional)

Claude Code supports plugins via the built-in marketplace:

```
/plugin                              # Open plugin menu
  → /marketplace                     # Browse available plugins
    → /marketplace add wshobson/agents   # Add a marketplace
  → /install code-review-ai          # Install a plugin
```

### Recommended: Code Review Agent

Automated code reviews before committing:
```
/marketplace add wshobson/agents
/install code-review-ai@claude-code-workflows
```

## Upgrading

When running `./install.sh --update`, you may be prompted to migrate between versions.

### v1 → v2: Coding Standards to Skills

Inline coding standards in `CLAUDE.md` are replaced by context-aware skills:

| Before (v1) | After (v2) |
|-------------|------------|
| `## Coding Standards` in CLAUDE.md | `~/.claude/skills/standards-python/` |
| Always loaded | Auto-loads based on Tech Stack |
| One size fits all | Language-specific |

**What happens during migration:**
1. Backup created: `~/.claude/CLAUDE.md.bak`
2. `## Coding Standards` section removed from CLAUDE.md
3. `## Code Review Checklist` section removed from CLAUDE.md
4. Skills installed separately in `~/.claude/skills/`

See [ADR-007](docs/adr/007-coding-standards-as-skills.md) for technical details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to:
- Report bugs and suggest features
- Submit pull requests
- Add new modules

## License

MIT License - See [LICENSE](LICENSE) for details.

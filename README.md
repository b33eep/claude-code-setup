# Claude Code Setup

[![CI](https://github.com/b33eep/claude-code-setup/actions/workflows/test.yml/badge.svg)](https://github.com/b33eep/claude-code-setup/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modular setup for Claude Code that solves context loss and keeps your workflow consistent.

## The Problem

> *"Claude forgets everything after /compact"*
>
> *"Context full, all my progress is gone"*
>
> *"Where did I leave off yesterday?"*
>
> *"What should I even put in CLAUDE.md?"*
>
> *"My code style is inconsistent across sessions"*

Sound familiar?

## The Solution

| Problem | How we solve it |
|---------|-----------------|
| Context loss | External memory via two CLAUDE.md files |
| "Where was I?" | `/catchup` shows what changed + next steps |
| "What goes in CLAUDE.md?" | `/init-project` generates it for your project |
| Inconsistent code | Coding standards load automatically per tech stack |
| "Which MCP servers?" | Curated selection, one-click install |
| "How to document decisions?" | Records for design + planning → becomes documentation |
| "When is context full?" | ccstatusline shows live usage (e.g., `Ctx: 70%`) |

**Smart skill loading:** Working on a Python project? Python standards load automatically. Writing a shell script? Shell standards appear. No manual setup, no commands to remember.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/quick-install.sh | bash
```

![Install Demo](docs/assets/install.gif)

Or clone manually:

```bash
git clone https://github.com/b33eep/claude-code-setup.git
cd claude-code-setup
./install.sh
```

The installer guides you through selecting MCP servers, coding standards, and tools.

**After install:** Disable auto-compact in Claude Code settings (`Cmd+,` → Config → Auto-compact: `false`). This setup uses controlled `/clear-session` instead.

## How It Works

**Two files + Records = persistent memory:**

| File | Location | Purpose |
|------|----------|---------|
| Global | `~/.claude/CLAUDE.md` | Your workflow, standards, conventions |
| Project | `your-project/CLAUDE.md` | Current status, tasks, decisions |
| Records | `your-project/docs/records/` | Design docs, implementation plans |

Both CLAUDE.md files load automatically. Records are referenced when relevant (e.g., "Why did we choose X?").

**Records:** Start as solution design or implementation plan, become permanent documentation. One file per decision, versioned in Git.

## Daily Workflow

```
┌─────────────────────────────────────────────────────────┐
│  Session Start                                          │
│  /catchup → See what changed, what's next               │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  Work                                                   │
│  Tasks in CLAUDE.md, implement, test                    │
│  Monitor context: Ctx: 70% (via ccstatusline)           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  Session End (when context fills up)                    │
│  /clear-session → Saves status, commits                 │
│  /clear → Fresh start with full memory                  │
└─────────────────────────────────────────────────────────┘
```

https://github.com/user-attachments/assets/e385aa9e-7480-441c-8a30-e196992de9f9

**First time on a project?** Run `/init-project` once to generate the project CLAUDE.md.

> **Tip:** The installer sets up [ccstatusline](https://github.com/sirmalloc/ccstatusline) to show context usage in your terminal. When it hits ~80%, time for `/clear-session`.

## Updates

Stay in Claude Code - no terminal needed:

| Command | What it does |
|---------|--------------|
| `/upgrade-claude-setup` | Update + discover new modules |
| `/add-custom <url>` | Add custom modules (company/personal) |
| `/upgrade-custom` | Pull latest from custom repo |

```
You: /upgrade-claude-setup
Claude: Upgraded claude-code-setup: v4 → v5

        New modules available:
        - standards-javascript (JS/Node.js standards)

        Install any of these?
You: yes, standards-javascript
Claude: ✓ standards-javascript installed
```

<details>
<summary>Shell commands</summary>

```bash
./install.sh --add           # Add more modules
./install.sh --update        # Update all modules
./install.sh --update --yes  # Non-interactive (used by /upgrade-claude-setup)
./install.sh --list          # Show installed modules
```

</details>

## What's Included

### Coding Standards (auto-loading)

| Skill | Loads when Tech Stack contains |
|-------|--------------------------------|
| JavaScript | javascript, nodejs, express, fastify, npm... |
| Python | python, fastapi, django, flask, pytest... |
| TypeScript | typescript, react, nextjs, vue, angular... |
| Shell | bash, sh, shell, zsh, shellcheck... |

Standards load based on your project's `Tech Stack:` in CLAUDE.md. Writing a shell script in a Python project? Shell standards load for that file.

### MCP Servers

| Server | Description | API Key |
|--------|-------------|---------|
| `pdf-reader` | Read and analyze PDFs | No |
| `brave-search` | Web search (2000 free/month) | Yes |
| `google-search` | Google Custom Search | Yes |

### Other Skills

| Skill | Description |
|-------|-------------|
| `create-slidev-presentation` | Create Slidev slide decks |

## For Teams

Create a company repo with your standards:

```
company-claude-modules/
├── mcp/
│   └── internal-api.json
└── skills/
    └── company-standards/
```

Setup for team members:

```
You: /add-custom git@company.com:team/claude-modules.git
Claude: Cloned to ~/.claude/custom
        Found: 2 skills, 1 MCP server
        Run install.sh --add to install.
```

Custom skills **override** built-in ones. Your `standards-python` replaces ours.

<details>
<summary>Custom module formats</summary>

**SKILL.md format:**

```markdown
---
name: standards-python
description: Company Python standards
type: context
applies_to: [python, fastapi, django]
---

# Your Standards

Content here...
```

**MCP server format:**

```json
{
  "name": "my-server",
  "description": "My MCP server",
  "config": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "my-package"]
  },
  "requiresApiKey": false
}
```

</details>

## Solo vs Team Mode

When running `/init-project`:

| Mode | CLAUDE.md | Use case |
|------|-----------|----------|
| **Solo** | In `.gitignore` | Personal notes, not shared |
| **Team** | Tracked in Git | Shared status for everyone |

## Plugins (Optional)

Claude Code has a built-in plugin marketplace:

```
/marketplace add wshobson/agents
/install code-review-ai@claude-code-workflows
```

## File Structure

<details>
<summary>Repository structure</summary>

```
claude-code-setup/
├── templates/
│   ├── VERSION
│   ├── project-CLAUDE.md
│   └── base/global-CLAUDE.md
├── mcp/
├── skills/
├── commands/
├── tests/
├── quick-install.sh
└── install.sh
```

</details>

<details>
<summary>Installed structure</summary>

```
~/.claude/
├── CLAUDE.md
├── settings.json
├── installed.json
├── commands/
├── skills/
├── templates/
└── custom/         # Your custom modules

~/.claude.json      # MCP servers
```

</details>

## Development

```bash
./tests/test.sh              # Run all tests
./tests/test.sh 01           # Run scenario 01
./tests/test.sh version      # Pattern match
```

Tests run in isolation - your `~/.claude` stays untouched.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgments

- [ccstatusline](https://github.com/sirmalloc/ccstatusline) by sirmalloc
- [moai-lang-shell](https://github.com/AJBcoding/claude-skill-eval/tree/main/skills/moai-lang-shell) by AJBcoding

## License

MIT - See [LICENSE](LICENSE).

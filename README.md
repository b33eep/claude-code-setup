# Claude Code Setup

```diff
+    _____ _                 _        _____          _
+   / ____| |               | |      / ____|        | |
+  | |    | | __ _ _   _  __| | ___ | |     ___   __| | ___
+  | |    | |/ _` | | | |/ _` |/ _ \| |    / _ \ / _` |/ _ \
+  | |____| | (_| | |_| | (_| |  __/| |___| (_) | (_| |  __/
+   \_____|_|\____|\_____|\____|\___|\_____\___/ \____|\___|
-                                                     Setup
```

[![CI](https://github.com/b33eep/claude-code-setup/actions/workflows/test.yml/badge.svg)](https://github.com/b33eep/claude-code-setup/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/platform-Linux-blue.svg)](https://www.linux.org/)
[![WSL](https://img.shields.io/badge/platform-WSL-blue.svg)](https://docs.microsoft.com/en-us/windows/wsl/)
[![Content v23](https://img.shields.io/badge/content-v23-blue.svg)](CHANGELOG.md)

---

## The Problem

Claude Code has a context limit. When it fills up, you have two options:

1. **Auto-Compact** - Claude summarizes the conversation, losing details and decisions
2. **/clear** - Everything is gone, you start from zero

Both options mean lost progress. And it gets worse:

**Daily friction:**
- "Where did I leave off yesterday?"
- "What decisions did we make last session?"
- "Why did we choose approach X over Y?"

**Inconsistency:**
- Code style varies between sessions
- Different formatting, different patterns
- No shared standards across the team

**Setup overhead:**
- "What should I even put in CLAUDE.md?"
- New team member = manual setup from scratch
- Company standards need to be copy-pasted everywhere

**Maintenance pain:**
- Updates overwrite your customizations
- Personal preferences get lost
- "When exactly is context getting full?"

## The Solution

| Problem | How we solve it |
|---------|-----------------|
| Context loss | Two CLAUDE.md files (global + project) as external memory |
| "Where was I?" | `/catchup` shows changes and next steps |
| Lost decisions | Records preserve design docs and reasoning |
| "When is context full?" | ccstatusline shows live usage (e.g., `Ctx: 70%`) |
| Inconsistent code | Coding standards load automatically per tech stack |
| "What goes in CLAUDE.md?" | `/init-project` generates it from a template |
| Team setup overhead | Custom modules repo - one command to install |
| Updates overwrite settings | User Instructions section survives updates |
| Staying current | `/claude-code-setup` updates without leaving Claude |

---

## Installation

### 1. Prerequisites (install yourself)

| Requirement | Why |
|-------------|-----|
| [Claude Code](https://claude.ai/download) | The CLI this setup extends |
| macOS, Linux, or WSL | Supported platforms |

Optional:
- [Node.js](https://nodejs.org/) - Required for context status line
- [Homebrew](https://brew.sh) (macOS) - For automatic jq installation

### 2. Run Installer

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/quick-install.sh)
```

![Install Demo](docs/assets/install.gif)

The installer:
- Installs `jq` automatically (via Homebrew or binary)
- Lets you select MCP servers, coding standards, and tools
- Configures [ccstatusline](https://github.com/sirmalloc/ccstatusline) for context monitoring
- Sets up commands, skills, and templates

<details>
<summary>Alternative: Clone and run manually</summary>

```bash
git clone https://github.com/b33eep/claude-code-setup.git
cd claude-code-setup
./install.sh
```

</details>

### 3. Disable Auto-Compact (Required)

> **This is critical.** Auto-compact destroys context unpredictably. This setup uses `/wrapup` → `/clear` instead.

**Claude Code Settings** → `Cmd+,` (macOS) or `Ctrl+,` (Linux)

```
Auto-compact: false
```

### 4. Future Updates

After initial install, update exclusively via Claude Code:

```
You: /claude-code-setup
Claude: Installed: v15, Available: v16
        What would you like to do?
You: Upgrade
```

No terminal needed. Your customizations in the "User Instructions" section are preserved.

---

## Core Concept

### Two CLAUDE.md Files

| File | Location | Purpose |
|------|----------|---------|
| **Global** | `~/.claude/CLAUDE.md` | Your workflow, conventions, preferences |
| **Project** | `your-project/CLAUDE.md` | Current status, tasks, next steps |

Both load automatically. Claude always knows your workflow and where you left off.

### Records

Design decisions, implementation plans, and feature specs go in `docs/records/`. They start as planning docs and become permanent documentation.

```
docs/records/
├── 001-authentication-design.md
├── 002-api-refactoring.md
└── 003-caching-strategy.md
```

### Auto-Loading Skills

Coding standards load automatically based on your project's tech stack:

| Your Tech Stack | Standards that load |
|-----------------|---------------------|
| Python, FastAPI | Python standards |
| TypeScript, React | TypeScript standards |
| Bash scripts | Shell standards |

Writing a shell script in a Python project? Shell standards load for that file.

### User Instructions (Preserved)

The global CLAUDE.md has a "User Instructions" section at the bottom. Add your personal preferences there - they survive updates.

```markdown
<!-- USER INSTRUCTIONS START -->
- Always respond in German
- Use formal code comments
- My API keys are in ~/.config/secrets/
<!-- USER INSTRUCTIONS END -->
```

---

## Workflow

```
┌─────────────────────────────────────────────────────────┐
│  SESSION START                                          │
│                                                         │
│  /catchup → See what changed, what's next               │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  WORK                                                   │
│                                                         │
│  Implement tasks from CLAUDE.md                         │
│  /todo → Add new todos (creates Records if complex)     │
│  Monitor context: Ctx: 70% (via ccstatusline)           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  SESSION END (when context fills up)                    │
│                                                         │
│  /wrapup → Saves status to CLAUDE.md, commits    │
│  /clear → Fresh start with full memory                  │
└─────────────────────────────────────────────────────────┘
```

https://github.com/user-attachments/assets/e385aa9e-7480-441c-8a30-e196992de9f9

**First time on a project?** Run `/init-project` to generate the project CLAUDE.md.

---

## Features

### Commands

| Command | What it does |
|---------|--------------|
| `/catchup` | Shows recent changes and next steps |
| `/wrapup` | Saves status to CLAUDE.md, commits changes |
| `/init-project` | Generates project CLAUDE.md from template |
| `/claude-code-setup` | Check status, upgrade base + custom, install modules |
| `/add-custom <url>` | Add custom modules from Git repo |
| `/todo` | Add todos to CLAUDE.md, create Records for complex ones |
| `/skill-creator` | Create your own custom skills |

### Coding Standards (auto-loading)

| Skill | Loads for |
|-------|-----------|
| `standards-python` | python, fastapi, django, flask, pytest |
| `standards-typescript` | typescript, react, nextjs, vue, angular |
| `standards-javascript` | javascript, nodejs, express, npm |
| `standards-shell` | bash, sh, shell, zsh, shellcheck |

### Other Skills

| Skill | Description |
|-------|-------------|
| `youtube-transcript` | Download YouTube transcripts with frame extraction at visual references |
| `create-slidev-presentation` | Create Slidev slide decks (loads when you ask for presentations) |

#### YouTube Transcript Skill

Analyze YouTube videos by downloading transcripts and extracting frames at visual reference points.

```
You: /youtube-transcript https://www.youtube.com/watch?v=VIDEO_ID
Claude: [Downloads transcript, detects "as you can see", "look at this diagram", etc.]
        [Extracts frames at those timestamps]
        [Presents transcript with embedded images]
```

**Features:**
- Auto-detects visual references (EN + DE)
- Extracts frames at key moments
- Works with auto-generated and manual captions

**Requirements:** `yt-dlp` and `ffmpeg` (installed automatically when you select the skill)

#### Slidev Presentation Skill

Create professional slide decks using [Slidev](https://sli.dev) - a Markdown-based presentation framework.

```
You: Create a presentation about our Q4 results
Claude: [Creates slides.md with YAML config, layouts, animations]
        [Sets up Slidev project structure]
```

**Features:**
- 17 built-in layouts + custom layouts
- Live code editors with syntax highlighting
- Mermaid diagrams, LaTeX math
- Export to PDF, PPTX, PNG

**Requirements:** Node.js >= 24.0.0

*Attribution: [AJBcoding/claude-skill-eval](https://github.com/AJBcoding/claude-skill-eval)*

### MCP Servers

| Server | Description | API Key |
|--------|-------------|---------|
| `pdf-reader` | Read and analyze PDFs | No |
| `brave-search` | Web search (2000 free/month) | Yes |
| `google-search` | Google Custom Search | Yes |

### Context Status Line

[ccstatusline](https://github.com/sirmalloc/ccstatusline) shows live context usage in your terminal:

```
Ctx: 45% | Model: opus | Branch: main
```

When it hits ~80%, time for `/wrapup`.

---

## Custom Modules

### Create Your Own Skills

```
You: /skill-creator
Claude: What type of skill?
        1. Command skill - Invoked with /skill-name
        2. Context skill - Auto-loads based on tech stack
```

Skills are saved to `~/.claude/custom/skills/`.

### For Teams

Create a company repo with shared standards:

```
company-claude-modules/
├── mcp/
│   └── internal-api.json
└── skills/
    └── company-standards/
```

Add for all team members:

```
You: /add-custom git@company.com:team/claude-modules.git
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

---

## Solo vs Team Mode

When running `/init-project`:

| Mode | CLAUDE.md | Use case |
|------|-----------|----------|
| **Solo** | In `.gitignore` | Personal notes, not shared |
| **Team** | Tracked in Git | Shared status for the team |

---

## Optional: Code Review Plugin

Claude Code has a built-in plugin marketplace:

```
/marketplace add wshobson/agents
/install code-review-ai@claude-code-workflows
```

After installing, the `code-review-ai:architect-review` agent is available.

---

## File Structure

<details>
<summary>What gets installed</summary>

```
~/.claude/
├── CLAUDE.md           # Global config (your workflow)
├── settings.json       # Claude Code settings
├── installed.json      # Tracks installed modules
├── commands/           # Slash commands
├── skills/             # Coding standards, tools
├── templates/          # Project CLAUDE.md template
└── custom/             # Your custom modules

~/.claude.json          # MCP server configs
```

</details>

<details>
<summary>Repository structure</summary>

```
claude-code-setup/
├── install.sh          # Main installer
├── quick-install.sh    # One-liner installer
├── lib/                # Modular install components
├── templates/          # CLAUDE.md templates
├── mcp/                # MCP server configs
├── skills/             # Coding standards
├── commands/           # Slash commands
└── tests/              # Test scenarios
```

</details>

---

## Development

```bash
./tests/test.sh              # Run all tests
./tests/test.sh 01           # Run scenario 01
./tests/test.sh version      # Pattern match
```

Tests run in isolation - your `~/.claude` stays untouched.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Roadmap

| Feature | Record |
|---------|--------|
| Optional hooks for workflow automation | [012](docs/records/012-optional-hooks-automation.md) |

Have ideas? Open a [Discussion](https://github.com/b33eep/claude-code-setup/discussions).

## Acknowledgments

- [ccstatusline](https://github.com/sirmalloc/ccstatusline) by sirmalloc
- [moai-lang-shell](https://github.com/AJBcoding/claude-skill-eval/tree/main/skills/moai-lang-shell) by AJBcoding

## License

MIT - See [LICENSE](LICENSE).

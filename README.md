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
[![Docs](https://img.shields.io/badge/docs-b33eep.github.io-blue.svg)](https://b33eep.github.io/claude-code-setup/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/platform-Linux-blue.svg)](https://www.linux.org/)
[![WSL](https://img.shields.io/badge/platform-WSL-blue.svg)](https://docs.microsoft.com/en-us/windows/wsl/)
[![Content v38](https://img.shields.io/badge/content-v38-blue.svg)](CHANGELOG.md)

**Persistent memory for Claude Code via Markdown files.**

> 📖 **[Read the Documentation](https://b33eep.github.io/claude-code-setup/)** for detailed guides, tutorials, and reference.

---

## The Problem

Claude Code has a context limit. When it fills up:
- **Auto-Compact** loses details and decisions
- **/clear** starts from zero

## The Solution

| Problem | Solution |
|---------|----------|
| Context loss | Two CLAUDE.md files as external memory |
| "Where was I?" | `/catchup` shows changes and next steps |
| Lost decisions | Records preserve reasoning |
| Inconsistent code | Coding standards auto-load per tech stack |

---

## Quick Start

### 1. Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/quick-install.sh)
```

### 2. Disable Auto-Compact

**Claude Code Settings** → `Cmd+,` / `Ctrl+,` → Set `Auto-compact: false`

### 3. Use

```
/init-project    # Set up your project
/catchup         # Start each session
/wrapup          # End each session
/clear           # Clear context
```

---

## Features

### Commands

| Command | Description |
|---------|-------------|
| `/init-project` | Set up new project |
| `/catchup` | Resume after /clear |
| `/wrapup` | Save status before /clear |
| `/todo` | Manage todos |
| `/design` | Structured feature design |
| `/add-custom` | Add custom modules |
| `/claude-code-setup` | Update and manage modules |

### Skills (Auto-Loading)

| Skill | Tech Stack |
|-------|------------|
| Java | java, maven, gradle, spring, junit |
| JavaScript | javascript, nodejs, express |
| Kotlin | kotlin, gradle, maven, kotlinx-coroutines |
| Python | python, fastapi, django, flask |
| Shell | bash, sh, zsh |
| TypeScript | typescript, react, nextjs, vue |

### Tool Skills

| Skill | Description |
|-------|-------------|
| YouTube Transcript | Download transcripts with frame extraction |
| Slidev Presentations | Create Markdown slide decks |
| Skill Creator | Create custom skills |

### MCP Servers

| Server | Description |
|--------|-------------|
| pdf-reader | Read and analyze PDFs |
| brave-search | Web search |
| google-search | Google Custom Search |

### External Plugins

Install Claude plugins via the installer:

| Plugin | Description |
|--------|-------------|
| document-skills | Excel, Word, PowerPoint, PDF creation/editing |
| code-review-ai | AI-powered architectural review (recommended) |

---

## Documentation

📖 **[b33eep.github.io/claude-code-setup](https://b33eep.github.io/claude-code-setup/)**

- [Getting Started](https://b33eep.github.io/claude-code-setup/getting-started/installation)
- [Core Concepts](https://b33eep.github.io/claude-code-setup/concepts/two-claude-files)
- [Commands Reference](https://b33eep.github.io/claude-code-setup/commands/catchup)
- [Skills](https://b33eep.github.io/claude-code-setup/features/skills)
- [Session Workflow](https://b33eep.github.io/claude-code-setup/guides/daily-workflow)
- [Team Setup](https://b33eep.github.io/claude-code-setup/guides/team-setup)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Acknowledgments

- [ccstatusline](https://github.com/sirmalloc/ccstatusline) by sirmalloc
- [claude-skill-eval](https://github.com/AJBcoding/claude-skill-eval) by AJBcoding

## Contributors

- [@cheorges](https://github.com/cheorges)

## License

MIT - See [LICENSE](LICENSE).

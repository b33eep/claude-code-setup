# Claude Code Setup

A modular, minimal setup for Claude Code with a clear workflow and persistent memory via Markdown files.

> **Origin:** This project started as an innersource tool and has been open-sourced for the community. The clean Git history reflects a fresh start for public release.

## Features

- **Modular Installation** - Choose only the modules you need
- **Custom Modules** - Add your own standards, MCP servers, and skills
- **No /compact** - Uses "Document & Clear" workflow instead
- **External Memory** - CLAUDE.md + ADR files as persistent, versioned memory
- **Easy Updates** - Update modules without losing customizations

## Quick Start

```bash
git clone https://github.com/b33eep/claude-setup.git
cd claude-setup
./install.sh
```

The installer will guide you through selecting:
- Coding standards (Python, TypeScript, Design Patterns)
- MCP servers (PDF Reader, Brave Search, Google Search)
- Skills (Slidev Presentations)

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
│   ├── base/
│   │   └── global-CLAUDE.md      # Core: Workflow, conventions
│   └── modules/
│       └── standards/
│           ├── python.md         # Python coding standards
│           ├── typescript.md     # TypeScript/JS standards
│           └── design-patterns.md # Architecture patterns
├── mcp/                          # MCP server configurations
│   ├── pdf-reader.json
│   ├── brave-search.json
│   └── google-search.json
├── skills/                       # Optional skills
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

### Coding Standards

| Module | Description |
|--------|-------------|
| `python` | Python coding standards (PEP 8, type hints, best practices) |
| `typescript` | TypeScript/JavaScript standards (naming, async/await, error handling) |
| `design-patterns` | Architecture patterns (Strategy, Base Class, Batch Query) |

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
├── standards/
│   └── my-company.md     # Custom coding standards
├── mcp/
│   └── internal-api.json # Custom MCP server
└── skills/
    └── my-skill/         # Custom skill
```

### Custom Standards Format

Create a markdown file in `~/.claude/custom/standards/`:

```markdown
## My Company Standards

**Naming Conventions:**
- Use prefix `mc_` for all internal functions
- ...

**Code Style:**
...
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

## Workflow

### Session Start

```
1. CLAUDE.md is automatically loaded
2. Run /catchup to read changed files
```

### Development Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. SPECIFY                                             │
│     - Define user story / task in CLAUDE.md             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  2. IMPLEMENT                                           │
│     - Write code + tests                                │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  3. CODE REVIEW                                         │
│     - Run code-review-ai agent                          │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                    Back to 1.
                         or
              /clear-session → /clear
```

### Session End (at context limit)

```
1. /clear-session  → Documents status, commits changes
2. /clear          → Clear context
```

## Commands

| Command | Description |
|---------|-------------|
| `/catchup` | Read changed files after /clear |
| `/clear-session` | Document status before /clear |
| `/init-project` | Create CLAUDE.md for new project |

## Configuration

### Disable Auto-Compact

Auto-compaction can cause context loss. Disable it:

1. Open Claude Code settings: `/settings` or `Cmd+,`
2. Go to **Config** tab
3. Set **Auto-compact** to `false`

## Plugins (Optional)

### Code Review Agent

```bash
# Add marketplace
/marketplace add wshobson/agents

# Install agent
/install code-review-ai@claude-code-workflows
```

## Philosophy

Based on "How I Use Every Claude Code Feature":

> "Treat your CLAUDE.md as a high-level, curated set of guardrails and pointers."

> "Don't trust auto-compaction. Use /clear for simple reboots and the 'Document & Clear' method to create durable, external memory."

## Contributing

1. Fork the repository
2. Add your module to the appropriate directory
3. Submit a pull request

For new module types, open an issue first to discuss.

## License

MIT License - See [LICENSE](LICENSE) for details.

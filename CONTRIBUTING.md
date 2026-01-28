# Contributing to claude-code-setup

Thank you for your interest in contributing!

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/b33eep/claude-code-setup/issues) first
2. Create a new issue with:
   - Your OS (macOS, Linux distro, or WSL version)
   - Steps to reproduce
   - Expected vs actual behavior

### Suggesting Features

Open an issue with the `enhancement` label describing:
- The problem you're trying to solve
- Your proposed solution
- Alternative approaches you've considered

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run tests: `./tests/test.sh`
5. Run `shellcheck install.sh lib/*.sh` to verify shell script quality
6. Commit with [conventional commits](https://www.conventionalcommits.org/):
   - `feat(scope): description` for new features
   - `fix(scope): description` for bug fixes
   - `docs(scope): description` for documentation
   - `chore(scope): description` for maintenance
   - Scope is required (e.g., `install`, `skills`, `readme`)
7. Submit a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git
cd claude-code-setup

# Install shellcheck for linting
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt install shellcheck

# Arch
sudo pacman -S shellcheck

# Fedora
sudo dnf install ShellCheck

# Run linter
shellcheck install.sh lib/*.sh

# Run tests
./tests/test.sh
```

## Code Style

### Shell Scripts

- Follow [ShellCheck](https://www.shellcheck.net/) recommendations
- See [`skills/standards-shell/SKILL.md`](skills/standards-shell/SKILL.md) for detailed guidelines

### Markdown

- Use consistent header hierarchy
- Include code examples where helpful
- Keep lines under 120 characters

## Adding New Modules

### New Skill

1. Create `skills/your-skill/` directory
2. Add `SKILL.md` with frontmatter:
   ```markdown
   ---
   name: your-skill
   description: What this skill does
   type: context  # or "command"
   applies_to: [language, framework]
   ---

   # Your Skill Content
   ```
3. Test with `./install.sh`

### New MCP Server

1. Create `mcp/your-server.json`
2. Follow existing format (see `pdf-reader.json`)
3. Document API key requirements if applicable

## Questions?

Open an issue with the `question` label.

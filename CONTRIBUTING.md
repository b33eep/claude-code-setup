# Contributing to claude-code-setup

Thank you for your interest in contributing!

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/b33eep/claude-code-setup/issues) first
2. Create a new issue with:
   - Your macOS version
   - Your Homebrew version (`brew --version`)
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
4. Run `shellcheck install.sh` to verify shell script quality
5. Test your changes locally
6. Commit with [conventional commits](https://www.conventionalcommits.org/):
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `chore:` for maintenance
7. Submit a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claude-setup.git
cd claude-code-setup

# Install shellcheck for linting
brew install shellcheck

# Run linter
shellcheck install.sh
```

## Code Style

### Shell Scripts

- Follow [ShellCheck](https://www.shellcheck.net/) recommendations
- Use `set -e` for error handling
- Quote variables to prevent word splitting
- Use `[[ ]]` instead of `[ ]` for conditionals

### Markdown

- Use consistent header hierarchy
- Include code examples where helpful
- Keep lines under 120 characters

## Adding New Modules

### New Coding Standard

1. Create `templates/modules/standards/your-standard.md`
2. Follow existing format (see `python.md`)
3. Test with `./install.sh`

### New MCP Server

1. Create `mcp/your-server.json`
2. Follow existing format (see `pdf-reader.json`)
3. Document API key requirements if applicable

### New Skill

1. Create `skills/your-skill/` directory
2. Add `SKILL.md` with skill definition
3. Include any required assets

## Questions?

Open an issue with the `question` label.

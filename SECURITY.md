# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT** create a public GitHub issue
2. Email the maintainer or use [GitHub's private vulnerability reporting](https://github.com/b33eep/claude-code-setup/security/advisories/new)
3. Include details about the vulnerability and steps to reproduce

You can expect a response within 48 hours.

## Scope

This project is a configuration installer. Security considerations include:

- **API Keys**: Never stored in the repository. Users provide keys at install time, stored locally in `~/.claude.json`
- **Shell Script**: `install.sh` runs with user permissions only
- **No Network Calls**: The installer itself makes no network requests (MCP servers may, but those are user-selected)

## Trust Model

This project follows the same trust model as package managers (npm, pip, brew):

| Source | Trust Level | Notes |
|--------|-------------|-------|
| Built-in modules | Trusted | Maintained by this project |
| Custom modules via `/add-custom` | User responsibility | User explicitly provides the repo URL |

### Skill Dependencies (deps.json)

Skills may include a `deps.json` file that specifies system dependencies to install. When you install such a skill, the installer will run the platform-specific install commands (e.g., `brew install ffmpeg`).

**This is expected behavior**, similar to:
- `npm install` running postinstall scripts
- `pip install` running setup.py
- `brew install` executing formula code

**Before using `/add-custom`** with an untrusted repository, review:
- The `deps.json` files in any skills
- The install commands specified for your platform

## Best Practices for Users

- Keep your `~/.claude.json` file secure (contains API keys)
- Don't commit `~/.claude/` to version control
- Review custom modules before installing from untrusted sources
- Only use `/add-custom` with repositories you trust

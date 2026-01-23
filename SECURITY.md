# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT** create a public GitHub issue
2. Email the maintainer or use [GitHub's private vulnerability reporting](https://github.com/b33eep/claude-setup/security/advisories/new)
3. Include details about the vulnerability and steps to reproduce

You can expect a response within 48 hours.

## Scope

This project is a configuration installer. Security considerations include:

- **API Keys**: Never stored in the repository. Users provide keys at install time, stored locally in `~/.claude.json`
- **Shell Script**: `install.sh` runs with user permissions only
- **No Network Calls**: The installer itself makes no network requests (MCP servers may, but those are user-selected)

## Best Practices for Users

- Keep your `~/.claude.json` file secure (contains API keys)
- Don't commit `~/.claude/` to version control
- Review custom modules before installing from untrusted sources

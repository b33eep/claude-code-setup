# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Content v6: Rename ADR to Records - broader scope for design docs, feature specs, and implementation plans
- Content v5: Installation & upgrade improvements (Record-011)
  - Add `quick-install.sh` for curl one-liner installation
  - Add `/upgrade-claude-setup` command for in-session updates
  - Add `/add-custom` command for custom module repositories
  - Add `/upgrade-custom` command for updating custom repos
  - Separate project template to `templates/project-CLAUDE.md`
  - Add 4 new test scenarios (06-09)
- Content v4: Add MCP web search preference - prefer google-search/brave-search over built-in WebSearch when installed
- Content v3: Improved skill auto-loading (Record-010) - concrete instructions for session-start, task-based, and review-agent loading
- Content v2: Add Shell/Bash coding standards skill (standards-shell)
- Content v1: Initial managed content (global prompt, commands, skills, MCP configs)

## [1.0.0] - 2026-01-23

### Added
- Initial public release
- Modular installation system with `--add`, `--update`, `--list` flags
- Coding standards modules: Python, TypeScript, Design Patterns
- MCP server configurations: pdf-reader, brave-search, google-search
- Skills: create-slidev-presentation
- Custom modules support via `~/.claude/custom/`
- Workflow commands: `/catchup`, `/clear-session`, `/init-project`
- GitHub Actions CI for automated testing
- Documentation: README, CONTRIBUTING, SECURITY, Records

[Unreleased]: https://github.com/b33eep/claude-code-setup/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/b33eep/claude-code-setup/releases/tag/v1.0.0

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Modular installation system with `--add`, `--update`, `--list`, `--version` flags
- Quick install via curl one-liner (`quick-install.sh`)
- Coding standards skills: Python, TypeScript, JavaScript, Shell
- MCP server configurations: pdf-reader, brave-search, google-search
- Skills: create-slidev-presentation, skill-creator
- Custom modules support via `~/.claude/custom/`
- Workflow commands: `/catchup`, `/wrapup`, `/init-project`
- Upgrade commands: `/claude-code-setup`, `/add-custom`, `/upgrade-custom`
- In-session updates via `/claude-code-setup` (no terminal needed)
- Solo/Team mode selection in `/init-project`
- Project template system (`~/.claude/templates/`)
- GitHub Actions CI for automated testing
- Documentation: README, CONTRIBUTING, SECURITY, 15 Records
- Content versioning system
- ccstatusline integration for context visibility

### Content Versions

- **v16**: Rename `/clear-session` to `/wrapup` for consistency with `/catchup`
- **v15**: Preserve user instructions in global CLAUDE.md during updates (section markers)
- **v14**: Strengthen "No Co-Authored-By" rule to override Claude Code default behavior
- **v13**: Add Linux support (Ubuntu/Debian, Arch, Fedora, openSUSE) and refactor install.sh into lib/ modules
- **v12**: Fix changelog format in `/claude-code-setup` output example
- **v11**: Clarify code-review-ai plugin is optional in global prompt
- **v10**: Rename `/upgrade-claude-setup` → `/claude-code-setup`, show delta, ask user before actions
- **v9**: Add `/skill-creator` command skill for creating custom skills
- **v8**: Add JavaScript/Node.js coding standards skill (standards-javascript)
- **v7**: Add `--yes`/`-y` flag to install.sh for non-interactive updates
- **v6**: Rename ADR to Records - broader scope for design docs, feature specs, implementation plans
- **v5**: Installation & upgrade improvements
  - Add `quick-install.sh` for curl one-liner installation
  - Add `/claude-code-setup` command for in-session updates
  - Add `/add-custom` and `/upgrade-custom` commands
  - Separate project template to `templates/project-CLAUDE.md`
- **v4**: Add MCP web search preference (google-search/brave-search over built-in WebSearch)
- **v3**: Improved skill auto-loading (session-start, task-based, review-agent)
- **v2**: Add Shell/Bash coding standards skill (standards-shell)
- **v1**: Initial managed content (global prompt, commands, skills, MCP configs)

[Unreleased]: https://github.com/b33eep/claude-code-setup/compare/main...HEAD

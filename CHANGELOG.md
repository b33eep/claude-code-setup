# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security

- Remove `eval` from deps.json dependency check ([PR #22](https://github.com/b33eep/claude-code-setup/pull/22))
  - Use `command -v $name` directly instead of eval'ing arbitrary check commands
  - Document trust model in SECURITY.md
  - Add `SKIP_SKILL_DEPS` env var for test isolation

### Content Versions

- **v22**: Add `/youtube-transcript` skill - download transcripts with automatic frame extraction ([Record 021](docs/records/021-youtube-transcript-skill.md))
- **v21**: Remove auto-permissions feature (may discourage new users) - reverts v19 ([Record 019](docs/records/019-upgrade-permissions.md))
- **v20**: Remove `/upgrade-custom` command (replaced by `/claude-code-setup`), add custom modules versioning ([Record 020](docs/records/020-custom-modules-versioning.md))
- **v19**: ~~Auto-configure permission allow rules~~ (rejected in v21)
- **v18**: Add `/todo` command, `/catchup` loads relevant Records, `/wrapup` syncs Records table ([Record 018](docs/records/018-todo-command.md))
- **v17**: `/catchup` reads project README.md first for context
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

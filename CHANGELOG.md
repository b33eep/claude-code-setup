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

- **v34**: Fix update notification hook to show message to user
  - Use `systemMessage` JSON output format for user-visible notifications
- **v33**: Add update notification hook ([Record 028](docs/records/028-update-notifications.md))
  - SessionStart hook checks for available updates at session start
  - Compares installed version with latest on GitHub
  - Checks custom repo for new commits via `git ls-remote`
  - Fail-silent on network errors, fast (~100-200ms)
- **v32**: Add restart warning after upgrade/changes
  - Tools (Read, Bash, etc.) may not work until Claude Code restart
  - Warning shown after `/claude-code-setup` upgrades, module installs, and removals
- **v31**: Add `--remove` flag to uninstall modules ([Record 027](docs/records/027-uninstall-modules.md))
  - Remove MCP servers, skills, and external plugins
  - Interactive toggle selection (same UX as installation)
  - Added to `/claude-code-setup` command options
- **v30**: `/claude-code-setup` inserts MCP config with placeholder instead of showing snippet
  - Config is added directly to `~/.claude.json` with `YOUR_API_KEY_HERE`
  - User only needs to replace one value, no copy/paste required
- **v29**: `/claude-code-setup` supports external plugins installation
  - Discovers available plugins from `external-plugins.json`
  - Adds marketplace via `claude plugin marketplace add` if needed
  - Installs plugins via `claude plugin install`
  - Shows restart hint after installation
- **v28**: `/claude-code-setup` shows manual config hint when MCP/module requires API key
  - Stdin consumed by menus prevents interactive API key prompts
  - Claude now shows exact config with placeholder for user to add key manually
- **v27**: Add `code-review-ai` plugin from claude-code-workflows
  - AI-powered architectural review and code quality analysis
- **v26**: Add External Plugins feature - install Claude plugins via installer ([Record 026](docs/records/026-external-plugins.md))
  - Uses official `claude plugin` CLI
  - Offers `document-skills` (Excel, Word, PowerPoint, PDF) from Anthropic
  - Custom plugins via `~/.claude/custom/external-plugins.json`
- **v25**: `/init-project` now creates `docs/notes/` folder and adds it to `.gitignore`
  - Completes Private Notes feature from v24
- **v24**: Add Private Notes feature - `docs/notes/*.open.md` loaded by `/catchup` ([Record 025](docs/records/025-private-notes.md))
  - Gitignored notes for sessions, research, TODOs
  - `.open.md` suffix marks active notes
  - Rename to `.md` to close
- **v23**: Add Decision Log feature - "Recent Decisions" section in project CLAUDE.md ([Record 023](docs/records/023-context-quality-improvements.md))
  - Small decisions with reasoning survive `/clear`
  - Added immediately when decision is made (not at /wrapup)
  - Max 20 entries, pruned by relevance
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

# Record 005: E2E Tests in GitHub Actions

**Status:** Accepted
**Date:** 2026-01-23

## Context

The install.sh script is the main entry point for users. It handles:
- Interactive module selection (standards, MCP servers, skills)
- File generation (CLAUDE.md, installed.json, .claude.json)
- Multiple modes (fresh install, --add, --update, --list)

Without automated testing, regressions can occur unnoticed. Manual testing is time-consuming and error-prone.

## Decision

Implement comprehensive E2E tests in GitHub Actions that validate all install.sh functionality on every push/PR to main.

### Test Targets

| Test | What it validates |
|------|-------------------|
| `--help` | Shows usage without error |
| `--list` (before install) | Works with empty state |
| Fresh install | Creates all expected files |
| File content verification | CLAUDE.md contains selected standards |
| Tracking verification | installed.json tracks selected modules |
| MCP config verification | .claude.json contains MCP server configs |
| Skills verification | Skills are copied to ~/.claude/skills/ |
| `--list` (after install) | Shows installed modules correctly |
| `--add` | Adds modules without breaking existing |
| `--update` | Updates modules, preserves installed.json |

### Expected Files After Install

```
~/.claude/
  CLAUDE.md           # Global config with selected standards
  installed.json      # Tracks installed modules
  commands/           # Slash commands (catchup, clear-session, init-project)
  skills/             # Installed skills
~/.claude.json        # MCP server configurations
```

### Test Environment

- **Runner:** `macos-latest` (primary target platform)
- **Non-interactive mode:** Use `echo -e` to simulate user input
- **Module selection:** By index numbers (alphabetically sorted)

### MCP Testing Strategy

**Decision: No real API keys in CI**

The E2E tests validate the **installer**, not the MCP servers themselves. Therefore:

| MCP Server | API Key Required | Test Strategy |
|------------|------------------|---------------|
| pdf-reader | No | Full install, verify config |
| brave-search | Yes | Dummy key (`test-key-123`) |
| google-search | Yes | Dummy key (`test-key-123`) |

**What we verify:**
- Config is written to `~/.claude.json`
- JSON structure is valid
- Key placeholders are replaced
- MCP server entry exists in config

**What we don't verify:**
- API calls work (not installer's responsibility)
- Keys are valid (would require real keys)

**Why no real API keys:**
- Installer doesn't validate keys, only writes them to config
- Real keys would add complexity (GitHub Secrets management)
- Cost per API call in CI
- Security risk if keys leak
- No additional value for installer testing

### Verification Criteria

1. **File existence:** All expected files/directories exist
2. **Content validation:** `grep` for expected content in CLAUDE.md
3. **JSON validation:** `jq` queries to verify JSON structure
4. **MCP validation:** `jq` queries to verify MCP entries in .claude.json
5. **Idempotency:** `--update` doesn't corrupt state
6. **Additivity:** `--add` appends without overwriting

## Alternatives

### Test Framework

| Alternative | Pros | Cons |
|-------------|------|------|
| Unit tests only | Fast, isolated | Misses integration issues |
| Docker-based tests | Reproducible | Slow, overkill for bash script |
| Manual testing | No setup needed | Error-prone, not scalable |
| **E2E in GitHub Actions** | Real environment, automated | Slightly slower than unit tests |

### MCP API Keys

| Alternative | Pros | Cons |
|-------------|------|------|
| Real keys in GitHub Secrets | Tests actual API connectivity | Cost, security risk, overkill |
| Skip MCP tests entirely | Simple | Misses config generation bugs |
| **Dummy keys + structure validation** | Tests installer logic, no cost | Doesn't verify API works |

## Consequences

### Positive
- Every PR is validated before merge
- Regressions caught immediately
- Confidence in releases
- Documentation of expected behavior

### Negative
- CI minutes consumed
- Tests must be maintained
- Non-interactive simulation may miss edge cases

## References

- [GitHub Actions Workflow](.github/workflows/test.yml)
- [install.sh](../../install.sh)

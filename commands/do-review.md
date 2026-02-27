# Do Review: Code Review via comprehensive-review

Trigger a code review on your recent changes using the comprehensive-review plugin. This is Step 3 in the Development Flow — review before committing.

## Usage

```
/do-review                    # Review all uncommitted changes
/do-review HEAD~3..HEAD       # Review a specific commit range
/do-review --branch           # Review current branch vs main
/do-review --security         # Include security audit
/do-review --full             # Run all 3 review agents (alias for --security)
```

## Tasks

### 1. Validate arguments and determine review scope

Parse arguments into **scope** and **agent flags**:

- **Scope args** (mutually exclusive): commit range (e.g. `HEAD~3..HEAD`), `--branch`, or no args
- **Agent flags** (optional, combinable with any scope): `--security`, `--full`

**Unrecognized argument** (not a scope arg or agent flag):
```
Usage: /do-review [HEAD~N..HEAD | --branch] [--security | --full]
```
Stop here. Do not proceed.

Based on scope:

| Invocation | Scope | Git command |
|-----------|-------|-------------|
| `/do-review` (no scope args) | All uncommitted changes | `git diff HEAD` |
| `/do-review HEAD~3..HEAD` | Specific commit range | `git diff HEAD~3..HEAD` |
| `/do-review --branch` | Current branch vs main | `git diff main...HEAD` |

Run the appropriate git diff command.

**If no changes found:**
```
Nothing to review. No changes detected.
```
Stop here. Do not proceed.

**If large changeset (20+ files or 500+ lines):**
```
Large changeset: [N] files, ~[M] lines changed.
Review may be less thorough. Continue as-is, or narrow the scope?
[Continue] / [Specify files or range]
```
If user narrows scope, re-run with the adjusted scope.

### 2. Prepare review context

Gather context for the review agents:

1. **Get the diff** — output of the git diff command from step 1
2. **List changed files** — extract file paths from the diff
3. **Load coding standards** — for each changed file, check if a matching coding standards skill exists:
   - Identify file extensions in the changeset
   - Read matching skills from `~/.claude/skills/` (follow the Skill Loading table in global CLAUDE.md)
   - Collect relevant standards content
4. **Read project context** — tech stack and current task from project CLAUDE.md (About section, Tech Stack, Current Status)

### 3. Run review agents

Determine which agents to spawn based on flags:

| Flag | Agents |
|------|--------|
| (none) | architect-review + code-reviewer |
| `--security` | architect-review + code-reviewer + security-auditor |
| `--full` | architect-review + code-reviewer + security-auditor |

Spawn all agents **in parallel** via the Task tool. Don't wait for one to finish before spawning the next.

**Agent 1: comprehensive-review:architect-review**

```
Review the following code changes from an architectural perspective.

## Project Context
Tech Stack: [from project CLAUDE.md]
Current task: [from Current Status table, if available]

## Changes
[git diff output]

## Changed Files
[list of file paths — read these for full context around the changes]

## Coding Standards
[relevant standards from loaded skills]

Focus on: system design, architecture patterns, SOLID principles, scalability, dependency management.
Be actionable — suggest specific improvements, not general observations.
Skip praise; focus on what can be improved.
If everything looks good, say so briefly.
```

**Agent 2: comprehensive-review:code-reviewer**

```
Review the following code changes for code quality and maintainability.

## Project Context
Tech Stack: [from project CLAUDE.md]
Current task: [from Current Status table, if available]

## Changes
[git diff output]

## Changed Files
[list of file paths — read these for full context around the changes]

## Coding Standards
[relevant standards from loaded skills]

Focus on: code quality, maintainability, error handling, best practices, production reliability, test coverage gaps.
Be actionable — suggest specific improvements, not general observations.
Skip praise; focus on what can be improved.
If everything looks good, say so briefly.
```

**Agent 3 (only with --security or --full): comprehensive-review:security-auditor**

```
Perform a security audit on the following code changes.

## Project Context
Tech Stack: [from project CLAUDE.md]
Current task: [from Current Status table, if available]

## Changes
[git diff output]

## Changed Files
[list of file paths — read these for full context around the changes]

Focus on: security vulnerabilities, OWASP top 10, input validation, authentication/authorization, secrets handling, injection attacks.
Be actionable — suggest specific fixes, not general warnings.
Skip praise; focus on what can be improved.
If everything looks good, say so briefly.
```

**Spawn configuration:**
- Agent 1: `subagent_type`: `comprehensive-review:architect-review`
- Agent 2: `subagent_type`: `comprehensive-review:code-reviewer`
- Agent 3: `subagent_type`: `comprehensive-review:security-auditor`
- Let agents read the full files themselves — don't paste entire file contents

**If a review agent fails because the plugin is not installed:**
```
comprehensive-review plugin is not installed. This command requires it.

Install it: /claude-code-setup → External Plugins
Or manually: claude plugin marketplace add wshobson/agents && claude plugin install comprehensive-review@claude-code-workflows
```
Stop here.

**If a review agent fails for other reasons:**
- If at least one agent completed: present the available results, note which agent(s) failed
- If all agents failed: show the error and stop

```
Review could not be completed: [error]
You can retry with /do-review or request a manual review.
```

### 4. Present findings

Collect results from all agents. Present consolidated findings grouped by perspective:

```
## Architecture Review (architect-review)
[findings]

## Code Quality Review (code-reviewer)
[findings]

## Security Audit (security-auditor) ← only if --security or --full
[findings]
```

Then ask:

```
Review complete. [N] agents, [M] findings total.

Incorporate feedback? [Yes / No / Pick specific items]
```

**If Yes:** Apply all suggestions from the review. Show what was changed. Run the diff again to confirm.

**If Pick specific items:** List all suggestions numbered (across all agents). User picks which to apply. Apply selected items.

**If No:** Acknowledge and move on. The feedback is visible in the conversation for reference.

### 5. After applying feedback (if applicable)

After incorporating feedback:

```
Changes applied. You can:
- Run /do-review again to verify
- Commit your changes
- Continue implementing
```

---

## Important notes

- **This reviews code, not designs.** For design review, use `/design --review`.
- **Review agents read files.** Pass the diff and file list — let them read full file contents for context. Don't paste entire files into the prompt.
- **Coding standards are included automatically.** The command loads matching skills based on file extensions in the changeset.
- **Agents run in parallel.** Default: 2 agents (architect-review + code-reviewer). With `--security`/`--full`: 3 agents.
- **This is not blocking.** The user decides when to review and whether to act on feedback.
- **Works with any git workflow.** Uncommitted changes, commit ranges, or branch diffs.

---

## Examples

### Review before committing (default: 2 agents)

```
User: /do-review

Claude: Reviewing uncommitted changes (4 files, ~120 lines)...

[Spawns comprehensive-review:architect-review and comprehensive-review:code-reviewer in parallel]

## Architecture Review (architect-review)

1. **Dependency direction:** `utils/auth.py` imports from `handlers/` — this
   inverts the dependency direction. Utils should not depend on handlers.

## Code Quality Review (code-reviewer)

1. **Error handling:** `process_items()` has a nested loop that could be
   O(n*m). Consider using a dict for lookups.

2. **Standards:** Function `getData` doesn't follow snake_case convention
   per project standards.

Review complete. 2 agents, 3 findings total.

Incorporate feedback? [Yes / No / Pick specific items]

User: Yes

Claude: Applied all 3 suggestions. Changes:
- Moved auth logic to handlers/, removed circular import
- Replaced nested loop with dict lookup in process_items()
- Renamed getData → get_data

Run /do-review again to verify, or commit your changes.
```

### Full review with security audit

```
User: /do-review --full

Claude: Reviewing uncommitted changes (4 files, ~120 lines)...

[Spawns all 3 agents in parallel]

## Architecture Review (architect-review)
[findings]

## Code Quality Review (code-reviewer)
[findings]

## Security Audit (security-auditor)

1. **Input validation:** `handle_upload()` uses user-supplied filename directly
   in path construction. Use `os.path.basename()` to prevent path traversal.

Review complete. 3 agents, 5 findings total.

Incorporate feedback? [Yes / No / Pick specific items]
```

### Review a branch before PR

```
User: /do-review --branch

Claude: Reviewing current branch vs main (12 files, ~340 lines across 5 commits)...

[Spawns comprehensive-review:architect-review and comprehensive-review:code-reviewer in parallel]

## Architecture Review (architect-review)
...

## Code Quality Review (code-reviewer)
...

Review complete. 2 agents, 4 findings total.
...
```

### No changes to review

```
User: /do-review

Claude: Nothing to review. No changes detected.
```

### Plugin not installed

```
User: /do-review

Claude: comprehensive-review plugin is not installed. This command requires it.

Install it: /claude-code-setup → External Plugins
Or manually: claude plugin marketplace add wshobson/agents && claude plugin install comprehensive-review@claude-code-workflows
```

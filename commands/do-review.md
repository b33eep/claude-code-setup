# Do Review: Code Review via code-review-ai

Trigger a code review on your recent changes using the code-review-ai plugin. This is Step 3 in the Development Flow — review before committing.

## Usage

```
/do-review                    # Review all uncommitted changes
/do-review HEAD~3..HEAD       # Review a specific commit range
/do-review --branch           # Review current branch vs main
```

## Tasks

### 1. Validate arguments and determine review scope

**Unrecognized argument** (not a commit range or `--branch`):
```
Usage: /do-review [HEAD~N..HEAD | --branch]
```
Stop here. Do not proceed.

Based on arguments:

| Invocation | Scope | Git command |
|-----------|-------|-------------|
| `/do-review` (no args) | All uncommitted changes | `git diff HEAD` |
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

Gather context for the review agent:

1. **Get the diff** — output of the git diff command from step 1
2. **List changed files** — extract file paths from the diff
3. **Load coding standards** — for each changed file, check if a matching coding standards skill exists:
   - Identify file extensions in the changeset
   - Read matching skills from `~/.claude/skills/` (follow the Skill Loading table in global CLAUDE.md)
   - Collect relevant standards content
4. **Read project context** — tech stack and current task from project CLAUDE.md (About section, Tech Stack, Current Status)

### 3. Run review agent

Spawn `code-review-ai:architect-review` via the Task tool with the following prompt:

```
Review the following code changes.

## Project Context
Tech Stack: [from project CLAUDE.md]
Current task: [from Current Status table, if available]

## Changes
[git diff output]

## Changed Files
[list of file paths — read these for full context around the changes]

## Coding Standards
[relevant standards from loaded skills]

Be actionable — suggest specific improvements, not general observations.
Skip praise; focus on what can be improved.
If everything looks good, say so briefly.
```

**Spawn configuration:**
- `subagent_type`: `code-review-ai:architect-review`
- Let the agent read the full files itself — don't paste entire file contents

**If the review agent fails because the plugin is not installed:**
```
code-review-ai plugin is not installed. This command requires it.

Install it: /claude-code-setup → External Plugins
Or manually: claude plugin marketplace add wshobson/agents && claude plugin install code-review-ai@claude-code-workflows
```
Stop here.

**If the review agent fails for other reasons:**
```
Review could not be completed: [error]
You can retry with /do-review or request a manual review.
```
Stop here.

### 4. Present findings

Display the review agent's output to the user. Then ask:

```
Review complete.

Incorporate feedback? [Yes / No / Pick specific items]
```

**If Yes:** Apply all suggestions from the review. Show what was changed. Run the diff again to confirm.

**If Pick specific items:** List the suggestions numbered. User picks which to apply. Apply selected items.

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
- **The review agent reads files.** Pass the diff and file list — let it read full file contents for context. Don't paste entire files into the prompt.
- **Coding standards are included automatically.** The command loads matching skills based on file extensions in the changeset.
- **This is not blocking.** The user decides when to review and whether to act on feedback.
- **Works with any git workflow.** Uncommitted changes, commit ranges, or branch diffs.

---

## Examples

### Review before committing

```
User: /do-review

Claude: Reviewing uncommitted changes (4 files, ~120 lines)...

[Spawns code-review-ai:architect-review]

Review findings:

1. **Security:** Input validation missing in `handle_upload()` — user-supplied
   filename is used directly in path construction. Use `os.path.basename()`.

2. **Code quality:** `process_items()` has a nested loop that could be
   O(n*m). Consider using a dict for lookups.

3. **Standards:** Function `getData` doesn't follow snake_case convention
   per project standards.

Review complete.

Incorporate feedback? [Yes / No / Pick specific items]

User: Yes

Claude: Applied all 3 suggestions. Changes:
- Added os.path.basename() wrapper in handle_upload()
- Replaced nested loop with dict lookup in process_items()
- Renamed getData → get_data

Run /do-review again to verify, or commit your changes.
```

### Review a branch before PR

```
User: /do-review --branch

Claude: Reviewing current branch vs main (12 files, ~340 lines across 5 commits)...

[Spawns code-review-ai:architect-review]

Review findings:
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

Claude: code-review-ai plugin is not installed. This command requires it.

Install it: /claude-code-setup → External Plugins
Or manually: claude plugin marketplace add wshobson/agents && claude plugin install code-review-ai@claude-code-workflows
```

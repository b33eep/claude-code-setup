# Wrapup: Document and Restart

Wrap up the session before `/clear`. Document the current status for the next session.

## Tasks

1. **Update CLAUDE.md**
   - Update "Current Status" table (story status)
   - Update "Next Step" with clear next action

2. **Archive Done items**
   - Remove rows with status "Done" from the Current Status table
   - Their history is preserved in git commits and Records
   - The Status table shows current work only (Open, In Progress)

3. **Prune Recent Decisions**
   - Review the Recent Decisions table. Remove entries that are:
     - Implementation details already captured in a Record
     - Superseded by later decisions
     - Only relevant to a feature that's now Done
   - Keep only decisions that a future session (working on a different feature) might need

4. **Create Record (if needed)**
   - Was a decision, design, or significant feature documented this session?
   - If yes: Create Record in `docs/records/`
   - Reference in Current Status or Future table if actively relevant

5. **Check: Development, Files, Architecture sections**
   - Were commands added/changed this session? (new scripts, changed test commands, new build steps) → Update `## Development`
   - Were files/directories added/removed/restructured? → Update `## Files`
   - Were architectural changes made? (new patterns, changed data flow, new integrations) → Update `## Architecture`
   - Only update if the session's work actually changed these. Don't rewrite for cosmetic reasons.
   - If a section contains only the template placeholder (text in `{curly braces}`), don't fill it in unless the session's work provides real content for it.
   - If a section doesn't exist yet in the project CLAUDE.md, skip it.
   - Keep updates concise — a few sentences or a short list. Detailed designs belong in Records.

6. **Review for missed decisions**
   - Were any decisions made this session that are not in Recent Decisions?
   - A decision has: an alternative, a non-obvious "why", future relevance, project-level scope
   - If yes: Add them now (better late than never)
   - This is a safety net - decisions should be added in real-time

7. **Git commit (if applicable)**

   First check: Is CLAUDE.md tracked in Git?
   ```
   git ls-files --error-unmatch CLAUDE.md 2>/dev/null
   ```

   - **If NOT tracked (Solo mode)**: Skip Git steps for CLAUDE.md
     - Only commit Records and code changes if any

   - **If tracked (Team mode)**: Commit CLAUDE.md updates
     - Stage: CLAUDE.md, docs/records/
     - Commit: `docs: update project status`

8. **Output summary**
   - What was documented in CLAUDE.md?
   - What was committed (if any)?
   - Reminder: Run `/clear` to clear context

## Git Commit Logic

```
Check: Is this a Git repo?
  └─ No  → Skip Git steps
  └─ Yes →
       Check: Is CLAUDE.md tracked?
       └─ No (Solo)  → Only commit Records/code if changed
       └─ Yes (Team) →
            Check for changes in CLAUDE.md, docs/records/
            └─ No changes → Skip commit
            └─ Changes found → Commit with "docs: update project status"
```

## Project Instructions

When updating CLAUDE.md, do not add, remove, or change any content between the `<!-- PROJECT INSTRUCTIONS START -->` and `<!-- PROJECT INSTRUCTIONS END -->` markers. Treat this section as read-only during /wrapup.

## Note

After this command, manually run `/clear`.

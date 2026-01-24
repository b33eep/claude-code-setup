# Clear Session: Document and Restart

Before `/clear`, document the current status for the next session.

## Tasks

1. **Update CLAUDE.md**
   - Update "Current Status" table (story status, tests)
   - Update "What was done in this session" section
   - Update "Next Step" with clear next action

2. **Create Record (if needed)**
   - Was an architecture decision made?
   - If yes: Create Record in `docs/records/`
   - Add link to CLAUDE.md architecture table

3. **Git commit (if applicable)**

   First check: Is CLAUDE.md tracked in Git?
   ```
   git ls-files --error-unmatch CLAUDE.md 2>/dev/null
   ```

   - **If NOT tracked (Solo mode)**: Skip Git steps for CLAUDE.md
     - Only commit Records and code changes if any

   - **If tracked (Team mode)**: Commit CLAUDE.md updates
     - Stage: CLAUDE.md, docs/records/
     - Commit: `docs: update project status`

4. **Output summary**
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

## Note

After this command, manually run `/clear`.

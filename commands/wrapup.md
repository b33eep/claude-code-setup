# Wrapup: Document and Restart

Wrap up the session before `/clear`. Document the current status for the next session.

## Tasks

1. **Update CLAUDE.md**
   - Update "Current Status" table (story status, tests)
   - Update "What was done in this session" section
   - Update "Next Step" with clear next action

2. **Create Record (if needed)**
   - Was a decision, design, or significant feature documented this session?
   - If yes: Create Record in `docs/records/`
   - Add link to CLAUDE.md Records table

3. **Sync Records table**
   - Scan `docs/records/` for all existing Records
   - Compare with the Records table in project CLAUDE.md
   - Add any missing Records to the table
   - This keeps CLAUDE.md in sync with the actual Records on disk

4. **Git commit (if applicable)**

   First check: Is CLAUDE.md tracked in Git?
   ```
   git ls-files --error-unmatch CLAUDE.md 2>/dev/null
   ```

   - **If NOT tracked (Solo mode)**: Skip Git steps for CLAUDE.md
     - Only commit Records and code changes if any

   - **If tracked (Team mode)**: Commit CLAUDE.md updates
     - Stage: CLAUDE.md, docs/records/
     - Commit: `docs: update project status`

5. **Output summary**
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

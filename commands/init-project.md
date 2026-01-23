# Init Project: Set Up New Project

Initialize a new project with CLAUDE.md and folder structure.

## Tasks

1. **Analyze project**
   - Check for existing files (package.json, pyproject.toml, Cargo.toml, etc.)
   - Detect tech stack and framework
   - Check if Git repository

2. **Ask about sharing mode**

   Ask the user:
   ```
   How will you use CLAUDE.md in this project?

   1) Solo - Add to .gitignore (personal workflow, not shared)
   2) Team - Track in Git (shared context for all developers)
   ```

   - **Solo**: Add `CLAUDE.md` to `.gitignore`
   - **Team**: Keep `CLAUDE.md` tracked in Git

3. **Create CLAUDE.md**
   - Use project template from global CLAUDE.md
   - Fill in detected project info
   - Add common development commands

4. **Create folder structure**
   - Create `docs/adr/` if it doesn't exist

5. **Update .gitignore (if Solo mode)**
   - Add `CLAUDE.md` to `.gitignore`
   - Create `.gitignore` if it doesn't exist

6. **Git commit (if Git repo)**
   - Stage CLAUDE.md (if Team mode), .gitignore, and docs/adr/
   - Commit: `chore: add CLAUDE.md project setup`

## Output

- Summary of what was created
- Detected tech stack
- Sharing mode (Solo/Team)
- Suggested next steps

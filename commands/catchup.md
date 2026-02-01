# Catchup: Understand Changed Files

After `/clear` or new chat, understand recent changes.

## Tasks

1. **Read project README.md**
   - If exists: Read `README.md` in project root
   - Understand project purpose and structure

2. **Read changed files**
   - If Git: `git diff --name-only HEAD~10` (last 10 commits)
   - Or: `git status` for uncommitted changes
   - Read relevant changed files

3. **Load relevant Records**
   - Check Current Status and Future tables in project CLAUDE.md
   - If work is in progress or a next step references a Record → Read that Record
   - Example: Status shows "OAuth2 | In Progress | [Record 019]" → Read `docs/records/019-oauth2-auth.md`
   - Only load Records relevant to current/next work, not all

4. **Check Recent Decisions**
   - Read the "Recent Decisions" table in project CLAUDE.md
   - Note any decisions relevant to current work
   - These are small decisions with reasoning that survived the last `/clear`

5. **Read open private notes**
   - Check for `docs/notes/*.open.md` files
   - If found: Read them (these are active session notes)
   - Summarize key points from open notes
   - These contain context from previous sessions (research, strategies, TODOs)

6. **Load context skills**
   - Check `Tech Stack:` in project CLAUDE.md
   - Load matching skills from `~/.claude/skills/` (see Skill Loading in global CLAUDE.md)
   - Example: Tech Stack includes "Bash" → Read `standards-shell/SKILL.md`

7. **Summary**
   - What was recently changed?
   - What Records were loaded and why?
   - Open notes found? Summarize key points
   - What's the next step according to CLAUDE.md?

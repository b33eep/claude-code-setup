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

3. **Load context skills**
   - Check `Tech Stack:` in project CLAUDE.md
   - Load matching skills from `~/.claude/skills/` (see Skill Loading in global CLAUDE.md)
   - Example: Tech Stack includes "Bash" → Read `standards-shell/SKILL.md`

4. **Summary**
   - What was recently changed?
   - What's the next step according to CLAUDE.md?

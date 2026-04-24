# Quality Checklist

Run through these before and after shipping a skill. Catches most problems before users hit them.

## Before you start

- [ ] Identified 2–3 concrete use cases (specific scenarios, not "help with X")
- [ ] Tools identified (built-in only, MCP server, or combination)
- [ ] Reviewed at least one example skill in a similar domain (see [anthropics/skills](https://github.com/anthropics/skills))
- [ ] Planned the folder structure (just `SKILL.md`, or `references/` / `assets/` / `scripts/` too?)

## During development — frontmatter

- [ ] Folder named in kebab-case
- [ ] `SKILL.md` file exists with exact filename (case-sensitive)
- [ ] YAML frontmatter has opening and closing `---` delimiters
- [ ] `name` field: kebab-case, matches folder name, no spaces/underscores/capitals
- [ ] `name` doesn't use `claude` or `anthropic` prefix
- [ ] `description` includes **what** the skill does AND **when** to use it
- [ ] `description` includes 2–4 concrete trigger phrases users might actually say
- [ ] `description` under 1024 characters
- [ ] No XML angle brackets (`<` or `>`) anywhere in frontmatter

### claude-code-setup harness fields (skip if distributing to Claude.ai / API directly)

- [ ] `type` is `command` or `context`
- [ ] For context skills: `applies_to` lists at least one tech-stack token
- [ ] For context skills: `file_extensions` includes relevant file types

## During development — content

- [ ] Decision flow is the first major section after Overview
- [ ] Critical rules stated once, clearly, near the top
- [ ] Every instruction is specific (what + how + success criteria)
- [ ] Tables/bullets used for enumerations, not prose
- [ ] Error handling covers the common 2–3 failure modes
- [ ] At least one worked example per major use case
- [ ] Anti-patterns section lists what NOT to do (if relevant)
- [ ] Code blocks specify the language (e.g. ` ```bash ` not just ` ``` `)
- [ ] Bundled references/assets/scripts linked with explicit relative paths
- [ ] No `README.md` inside the skill folder

## During development — size

- [ ] SKILL.md under 5000 words (count with `wc -w SKILL.md`)
- [ ] If over 5000 words: identified which sections to move to `references/`
- [ ] Each `references/` file is self-contained (doesn't require reading SKILL.md to understand)
- [ ] `assets/` contains templates (copy-then-modify), not documentation
- [ ] `scripts/` used only for deterministic steps (validation, parsing, math)

## Before upload / activation

### Triggering tests

- [ ] Tested 5+ "should trigger" queries — skill loads on ≥80%
- [ ] Tested 5+ "should NOT trigger" queries — skill loads on 0%
- [ ] Tested paraphrased versions of use cases — skill loads
- [ ] Verified skill doesn't overlap with existing skills (no fights for the same match)

### Functional tests

- [ ] At least one test per use case from Step 1
- [ ] Happy path produces correct output
- [ ] At least one error path tested (MCP down, auth failed, validation rejected)
- [ ] Edge cases considered (empty input, max-length input, unusual characters)

### Performance

- [ ] Baseline comparison run: without-skill vs. with-skill
- [ ] Skill reduces messages OR tool calls OR token count (ideally all three)
- [ ] Skill doesn't introduce new failure modes

### Packaging

- [ ] Directory tree is clean — no `.DS_Store`, no stray files
- [ ] If distributing: compressed as `.zip`, repo-level README (not inside skill folder)
- [ ] Version number in `metadata.version` if iteratively shipped

## After upload / activation

### First week

- [ ] Tested in real conversations (not just scripted tests)
- [ ] Monitored triggering — no obvious under/overtriggering
- [ ] Collected feedback from 2–3 users (if distributing to a team)

### First month

- [ ] Iterated on description if triggering is off
- [ ] Iterated on instructions if functional behavior is off
- [ ] Documented known limitations in a top-level comment or metadata
- [ ] Updated `version` on any meaningful change

## Common "I'm done" self-deceptions

Before declaring the skill done, check these:

- [ ] "It worked once" — test at least 5 times, varying the query
- [ ] "The tests are green" — also run a few queries that should NOT trigger; check for false positives
- [ ] "I'll document edge cases later" — document now, even briefly; "later" usually never happens
- [ ] "Users will figure it out" — if the invocation isn't obvious from the description, it's not obvious to users either
- [ ] "It's good enough" — often means "I'm tired of iterating"; one more pass usually helps

## Shipping checklist for open-source skills

Extra steps if publishing to GitHub or a skill marketplace:

- [ ] Repository has a top-level `README.md` for human visitors (with screenshots or short demo)
- [ ] `LICENSE` file in the repo
- [ ] `compatibility` field in frontmatter states OS / runtime / MCP requirements
- [ ] Example usage documented with real queries and expected outputs
- [ ] Issue template / contributing guidelines if accepting contributions
- [ ] Tagged release with semver (e.g. `v1.0.0`)

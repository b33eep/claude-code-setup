# Record 038: Agent Teams Commands — /with-advisor + /delegate

## Status

Implemented

---

## Context

Anthropic shipped **Agent Teams** (Feb 5, 2026) as an experimental Claude Code feature. It enables multiple Claude Code instances working together in parallel.

We validated two patterns through PoCs and identified two distinct use cases for Agent Teams — **augmentation** (expert watches over your shoulder) and **delegation** (colleague works on a parallel task).

---

## Problem

When working on non-trivial tasks, a single Claude Code session has two limitations:

1. **Context overload** — implementation, research, and review all compete for one context window. Deep research pollutes the coding context.
2. **Sequential work** — the user can only work on one thing at a time. Parallel tasks (writing tests while implementing, researching while coding) require switching back and forth.

---

## Solution: Two Commands

Two on-demand commands, each for a distinct use case:

| Command | Pattern | What happens | Human experience |
|---------|---------|-------------|-----------------|
| `/with-advisor` | Augmentation | Expert advisor(s) monitor your work | Full visibility — you work normally, experts advise |
| `/delegate` | Delegation | Teammate works on a separate task | Notification when done — you continue your own work |

```
# Augmentation: expert watches over your shoulder
/with-advisor "implement OAuth login with JWT tokens"

# Delegation: colleague works in parallel
/delegate "write tests for the auth module"
```

Both commands share: Agent Teams prerequisite, `/catchup` onboarding, same install/remove lifecycle.

---

## /with-advisor

An on-demand command that spawns expert advisor(s) for the current task. The user decides when they want advisor support.

```
/with-advisor "implement OAuth login with JWT tokens"
/with-advisor "optimize the slow database queries"
/with-advisor "design a plugin system for the CLI"
```

### How it works

```
Human ←→ Main (does the work, like normal single mode)
               ├── Advisor 1: [auto-selected based on task]
               └── Advisor 2: [only if genuinely needed, max 2]
```

1. User types `/with-advisor "task description"`
2. Main analyzes the task and decides which advisor expertise adds value
3. Main spawns advisor(s) as Agent Teams teammates
4. Each advisor onboards (project context + problem research)
5. Main shares planned approach with advisors — advisors challenge before coding starts
6. Main implements — asks advisors at decision points, sends progress updates at checkpoints
7. Human sees everything, can intervene anytime, decides what to act on

### Smart advisor selection

The command doesn't always spawn the same advisor. Main analyzes the task:

| Task | Advisors spawned | Why |
|------|-----------------|-----|
| "implement OAuth login" | Security Expert + Auth Domain Expert | Unfamiliar security-sensitive domain |
| "optimize database queries" | Performance Expert | Specific domain expertise needed |
| "refactor the auth module" | Codebase Patterns Expert | Large change, consistency matters |
| "fix typo in README" | None — "Task is too simple for advisors" | Overhead exceeds benefit |

**Max 2 advisors.** Only spawn a second if genuinely different expertise is needed.

### Advisor onboarding: `/catchup` + role

Each advisor runs the existing `/catchup` command first, then adds domain-specific research. No custom onboarding needed.

**Step 1 — `/catchup`** (existing command, reused):
- Reads project CLAUDE.md + global CLAUDE.md → project context, tech stack, current status
- Reads README.md → project purpose
- Reads changed files → knows what's happening right now
- Loads relevant Records → understands the current task
- Loads coding standards skills → knows the rules
- Reads open notes → has session context

**Step 2 — Domain research** (advisor does this naturally):
- Researches best practices in their specialty for the current task
- Forms an opinion on the right approach
- Understands what "good" looks like in this domain

**Step 3 — Challenge approach** (before implementation):
- Main shares planned approach with advisors
- Advisors challenge: poke holes, suggest alternatives, flag risks
- Main incorporates feedback or decides to proceed
- Only then does implementation begin

**Step 4 — Collaborate during implementation** (ongoing):
- Main asks advisors at decision points (forks, unclear tradeoffs, unfamiliar territory)
- Advisors give clear recommendations, not option lists
- Main sends progress updates at meaningful checkpoints
- Advisors review diffs and speak up if they spot issues

### Advisor spawn prompt

The spawn prompt is minimal — `/catchup` does the heavy lifting:

```
You are an advisor specialized in [DOMAIN]. Do NOT write or edit code.

First: run /catchup to understand the project and current work.

Then: research best practices in your domain for the current task:
Task: [TASK DESCRIPTION]

Send your initial assessment to the team lead, then go idle.

How you collaborate with Main:

1. BEFORE implementation: Main shares a planned approach with you.
   Challenge it — poke holes, suggest alternatives, flag risks.
   Be direct: "This won't work because..." or "Consider X instead".
   If Main decides to proceed despite your objection, accept the decision.
   Monitor for consequences during implementation instead.

2. DURING implementation: Main will ask you at decision points.
   Give a clear recommendation, not a list of options.
   If Main doesn't ask but you spot something in a diff — speak up.

3. PROGRESS UPDATES: Main sends updates after significant changes.
   Read the latest git diff and changed files.
   Focus on your specialty, skip the rest. Be concise.

Your specialty: [DOMAIN DESCRIPTION]
```

**Why this works:** `/catchup` already solves "understand the project" — Skills, Records, Notes, Standards all come for free. The advisor only needs to add domain expertise on top.

**Key principle:** The advisor's biggest value is **before** code is written — catching bad directions early. During implementation, they're a domain expert on call. This is fundamentally different from code review, which only happens after the fact.

### When to use

**Good fit:**
- Unfamiliar domain (auth, crypto, payments, performance)
- Multiple valid approaches — advisor researches tradeoffs
- Quality matters — real-time expert review
- Large codebase — advisor checks existing patterns

**Skip it:**
- Simple/mechanical tasks (fix typo, rename variable)
- Very small scope (overhead exceeds benefit)
- Pure research tasks (single session is better)

---

## PoC Evidence

Two PoCs ran on the same task (implementing a `/do-review` command) to compare patterns.

### Pattern A: Lead → Driver + Advisor (rejected)

Main delegates to a Driver (codes) and Advisor (reviews). Human sees only Lead summaries.

**Result:** Technically works — roles held, advisor was proactive, timing was good. But the human was blind. Couldn't see the actual work, couldn't intervene, had to review everything after the fact. Driver and Advisor reinforced each other unchecked, producing over-engineered output (201 lines).

### Pattern B: Main + Expert Advisor (selected)

Main does the work (human sees everything). Advisor monitors and advises in background.

**Result:** All hypotheses passed. Human had full visibility — saw every edit, every decision, all advisor messages. Could have intervened at any point. Advisor actively cut over-engineering, producing leaner output (161 lines).

### Comparison

| Metric | Pattern A | Pattern B |
|--------|-----------|-----------|
| Duration | ~7 min | ~5.5 min |
| Result | 201 lines | 161 lines (leaner) |
| Human visibility | Lead summaries only | Full |
| Human intervention | Not possible | Anytime |
| Over-engineering | Unchecked | Advisor actively cut |
| Reasoning visible | No | Yes (Main thinks out loud) |

**Conclusion:** Pattern B is clearly superior for human-in-the-loop work. Same advisor quality, dramatically better human experience, naturally leaner results.

### Live test: /with-advisor on Story 3

Used `/with-advisor` to implement the `/delegate` command itself. One CLI Design advisor.

**Finding:** The advisor pattern scales to both long and short tasks, but the mode shifts:
- **Long tasks (30+ min):** Advisor onboards in time, monitors real-time as designed
- **Short tasks (<10 min):** Advisor finishes onboarding after Main is done, effectively becomes a code reviewer

Both modes deliver value. In this session the advisor caught 2 collision bugs (hardcoded worktree path, fixed team name) and identified 3 UX improvements — all post-implementation. The user experience is the same either way: findings appear inline.

This should be reflected in the documentation — `/with-advisor` is not just real-time monitoring, it's expert feedback that adapts to task duration.

---

## /delegate

An on-demand command that spawns a teammate to work on a separate task independently. The user continues their own work and gets notified when the teammate finishes.

```
/delegate "write unit tests for the auth module"
/delegate "research how other CLIs handle plugin systems, summarize findings"
/delegate "refactor the database layer to use connection pooling"
```

### How it works

```
Human ←→ Main (continues current work)
               └── Delegate: [works on assigned task]
                              ├── Asks Main when clarification needed
                              └── Notifies Main when done with results
```

1. User types `/delegate "task description"`
2. Main spawns a teammate with the task
3. Teammate onboards (`/catchup`) and starts working
4. Main continues normally — user keeps working on their own task
5. If teammate needs clarification → asks Main, user sees and answers
6. When teammate finishes, user gets notified with the result
7. User reviews the result and decides what to do with it

### Write isolation: git worktree

Delegates that need to modify files in the repo work in a **git worktree** — a separate working directory on its own branch. This prevents conflicts with Main's work.

| Task type | Where delegate works | Why |
|-----------|---------------------|-----|
| Read-only (research, analysis) | Scratchpad / `/tmp` | No repo changes needed |
| Write (code, tests, refactoring) | `git worktree` on separate branch | Isolated from Main, no conflicts |

The delegate creates a worktree, works on its branch, and when done the user decides whether to merge.

### Delegate onboarding: `/catchup` + task

Same as `/with-advisor` — delegate runs `/catchup` first, then works on the task.

```
You are a teammate working on an independent task.

First: run /catchup to understand the project and current work.

Your task: [task description from user]

Rules:
- If you need to modify repo files: create a git worktree and work there
- If read-only (research, analysis): use scratchpad/tmp
- If you need clarification: ask Main — don't guess
- When done: summarize what you did, what changed, decisions made
```

### When to use

**Good fit:**
- Research tasks (find out how X works, summarize findings)
- Independent code tasks (write tests, refactor module, fix bugs)
- Anything where you want to keep working on something else in parallel

**Use `/with-advisor` instead when:**
- You need real-time expert feedback on YOUR work
- The task requires your judgment and decisions throughout
- You want to stay in control of the implementation

### Stopping a delegate

User can stop a delegate at any time via Agent Teams shutdown. The delegate's worktree can be kept (for partial work) or cleaned up.

### Key difference from `/with-advisor`

| Aspect | `/with-advisor` | `/delegate` |
|--------|----------------|------------|
| Who does the work | You (Main) | Teammate |
| Advisor/teammate role | Monitors YOUR work | Does THEIR own work |
| Your attention | On your task, advisors supplement | On your task, teammate works separately |
| Human visibility | Full (you see everything Main does) | Messages when asking or done |
| Intervention | Anytime (you're in Main) | Answer questions, review result, stop |
| Context | Shared (advisor watches your diffs) | Isolated (own worktree/scratchpad) |
| Repo writes | Advisor: none | Delegate: git worktree (isolated branch) |

---

## Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Two commands | `/with-advisor` + `/delegate` | Different use cases: augmentation vs delegation |
| Max advisors | 2 | Token cost scales linearly, 1-2 is sweet spot |
| Max delegates | 1 per `/delegate` call | Keep it simple, user can call multiple times |
| Advisor selection | Auto (Main analyzes task) | User shouldn't need to specify expertise type |
| Simple task rejection | Yes — refuse if too simple | Prevents wasted tokens |
| Mid-session spawning | Yes | User may realize they need help after starting |
| Agent Teams prerequisite | Runtime check + install wizard toggle | Commands always installed, check at runtime, hint if not enabled |
| Onboarding (both) | `/catchup` + role/task prompt | Reuses existing infrastructure, no custom onboarding |
| Delegate write isolation | `git worktree` for repo changes, scratchpad for read-only | Prevents conflicts with Main's work |
| Delegate communication | Can ask Main for clarification mid-task | User sees questions, answers, delegate continues |
| Token cost warning | No | Advisors save cost elsewhere (less over-engineering, fewer reviews). Document, don't warn. |
| Stopping | Via Agent Teams shutdown mechanism | User can stop advisors or delegates at any time |

---

## Delivery via claude-code-setup

### What ships

| Component | Path | Description |
|-----------|------|-------------|
| Command file | `commands/with-advisor.md` | Instructions for Claude: analyze task, spawn advisor(s) |
| Command file | `commands/delegate.md` | Instructions for Claude: spawn teammate for independent task |
| Install wizard | `install.sh` | Agent Teams toggle (independent from commands) |
| Global CLAUDE.md | `templates/base/global-CLAUDE.md` | Both commands in workflow + commands table |
| Docs | `website/pages/commands/with-advisor.mdx` | Usage guide |
| Docs | `website/pages/commands/delegate.mdx` | Usage guide |

### Install / remove lifecycle

| Action | Command file | Agent Teams env var |
|--------|-------------|-------------------|
| **Install** | Always installed (like other commands) | Separate toggle — user opts in |
| **Remove** | Removable via wizard | Stays (user may use Agent Teams independently) |
| **Upgrade** | Updated on content version bump | Unchanged |
| **Runtime** | Checks if Agent Teams is active, shows hint if not | — |

### Runtime prerequisite check

When user runs `/with-advisor` or `/delegate` but Agent Teams isn't enabled:

```
Agent Teams is not enabled. This command requires it.

Enable it: /claude-code-setup → Agent Teams
Or manually: add CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to ~/.claude/settings.json
```

---

## Stories

### Story 1: Enable Agent Teams via install wizard

As a claude-code-setup user,
I want to enable Agent Teams during install,
so that I can use `/with-advisor` and `/delegate` without manual config.

**AK:**
```
Given I run ./install.sh on a fresh system,
When the wizard reaches the Agent Teams step,
Then I see "Enable Agent Teams (experimental)?" with Yes/No options.

Given I select Yes,
When the wizard completes,
Then CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 is set in ~/.claude/settings.json.

Given I select No,
When the wizard completes,
Then no Agent Teams env var is added to settings.json.

Given Agent Teams is already enabled in settings.json,
When the wizard reaches the Agent Teams step,
Then it skips (idempotent).

Given I want to disable Agent Teams,
When I run /claude-code-setup and deselect Agent Teams,
Then the env var is removed from settings.json.
```

### Story 2: `/with-advisor` command

As a developer working on a complex task,
I want to get an expert advisor spawned for my current work,
so that I get proactive domain feedback without losing my flow.

**AK:**
```
Given I have Agent Teams enabled and a task in progress,
When I run /with-advisor "implement OAuth login",
Then Main analyzes the task, selects a fitting advisor type (e.g. security expert),
and spawns a teammate with /catchup onboarding and domain-specific role.

Given I run /with-advisor "fix typo in README",
When Main analyzes the task,
Then it responds "Task is too simple for advisors" and does not spawn.

Given the advisor has completed onboarding,
When Main has a planned approach,
Then Main shares it with the advisor for challenge before implementing.

Given the advisor challenges the approach,
When I see the feedback in my session,
Then I can incorporate it or decide to proceed anyway.

Given Main is implementing and hits a decision point,
When the advisor's domain expertise would help,
Then Main asks the advisor before choosing and tells me the decision.

Given the advisor hasn't finished onboarding when Main is ready,
When Main has been idle waiting,
Then Main starts implementing and shares the approach retroactively.

Given Agent Teams is NOT enabled in settings.json,
When I run /with-advisor "any task",
Then I see a hint: "Agent Teams is not enabled. Enable it: /claude-code-setup → Agent Teams".
```

### Story 3: `/delegate` command

As a developer working on one task,
I want to delegate a separate task to a teammate,
so that I can keep working while the other task gets done in parallel.

**AK:**
```
Given I have Agent Teams enabled and a task in progress,
When I run /delegate "write tests for the auth module",
Then a teammate is spawned with /catchup onboarding and the delegated task.

Given the delegate needs to modify repo files,
When it starts working,
Then it creates a git worktree on a separate branch.

Given the delegate has a read-only task (research, analysis),
When it starts working,
Then it uses the scratchpad/tmp directory (no worktree needed).

Given the delegate encounters an unclear requirement,
When it needs a decision from me,
Then it asks Main and waits for my answer before continuing.

Given the delegate finishes,
When the result is ready,
Then I get notified with a summary: what changed, decisions made, what needs review.

Given Agent Teams is NOT enabled in settings.json,
When I run /delegate "any task",
Then I see the same enablement hint as /with-advisor.
```

### Story 4: Templates, docs, release (Enabler)

As a claude-code-setup maintainer,
I want the new commands reflected in templates and documentation,
so that new and existing users discover and understand them.

**AK:**
```
Given a user installs claude-code-setup,
When the global CLAUDE.md is generated,
Then it contains /with-advisor and /delegate in the commands table and workflow section.

Given a user visits the docs site,
When they navigate to Commands,
Then they find pages for /with-advisor and /delegate with usage, examples, and guidance.

Given all stories are implemented,
When I prepare the release,
Then templates/VERSION is incremented, README badge updated, CHANGELOG entry added, all tests pass.
```

### Implementation order

```
Story 1 (wizard) ──→ Story 2 (/with-advisor) ──→ Story 4 (templates, docs, release)
                  └──→ Story 3 (/delegate) ─────┘
```

Stories 2+3 can run in parallel after Story 1. Story 4 wraps up when both are done.

---

## Scope

**In scope:**
- `/with-advisor` command (augmentation — expert monitors your work)
- `/delegate` command (delegation — teammate works on separate task)
- Smart advisor selection (auto, based on task)
- `/catchup`-based onboarding for both
- Install wizard integration (Agent Teams toggle)
- Documentation

**Out of scope:**
- More than 2 advisors (architecture supports it for later)
- Custom advisor/delegate definitions by user (future feature)
- Delegate chaining (delegate spawning sub-delegates)

---

## Related

- [Agent Teams Docs](https://code.claude.com/docs/en/agent-teams)
- PoC 1: Pattern A validation (2026-02-08, ~7 min, 201 lines)
- PoC 2: Pattern B validation (2026-02-08, ~5.5 min, 161 lines)

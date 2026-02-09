# Delegate: Independent Teammate for Parallel Work

Spawn a teammate to work on a separate task independently. You continue your own work and get notified when the teammate finishes.

Works for any independent task: coding, research, data analysis, information gathering, documentation, etc.

## Usage

```
/delegate "write unit tests for the auth module"
/delegate "research how other CLIs handle plugin systems, summarize findings"
/delegate "analyze the last 10 Milan matches and summarize their performance"
/delegate "summarize key findings from the 5 most cited papers on topic X"
/delegate "compare pricing models of top 5 SaaS competitors"
```

## Tasks

### 1. Validate arguments

The command requires a task description.

**No arguments:**
```
Usage: /delegate "task description"

Example: /delegate "write unit tests for the auth module"
```

Stop here. Do not proceed.

### 2. Assess task fitness

Delegation works best for independent tasks. If the task requires constant back-and-forth with the user or tight integration with ongoing work, suggest `/with-advisor` instead:

```
This task needs your continuous input. Use /with-advisor instead — it keeps you in the loop with expert feedback.
```

Stop here. Do not proceed. Otherwise, continue.

### 3. Classify task type

Determine whether the delegate needs to modify repo files or only read/research.
This applies to all tasks: development work, research, analysis, documentation, etc.

| Task type | Where delegate works | Examples |
|-----------|---------------------|----------|
| **Write** (code, docs, config) | `git worktree` on separate branch | "write tests", "refactor module", "add feature", "add documentation to repo" |
| **Read-only** (research, analysis, information gathering) | Scratchpad in `/tmp` | "research how X works", "analyze Milan's last games", "compare competitor pricing", "summarize key findings from papers" |

### 4. Create team and spawn delegate

Use Agent Teams (TeamCreate + Task tool) to spawn the delegate.

**Team setup:**
- Team name: `delegate-[short-task-slug]` (e.g., `delegate-auth-tests`). Use a unique name per delegation so multiple delegates can run concurrently.
- Create a task for tracking
- If a team with the same name already exists (user delegated the same task before), ask: "A delegate for this task is still active. Replace it? [Yes / No]". If Yes, shut down the existing delegate first (SendMessage with `type: shutdown_request`), delete the team, then create a new one. If No, stop here.

**For write tasks, spawn a teammate with this prompt:**

```
You are a teammate working on an independent task. You CAN write and edit code.

First: run /catchup to understand the project and current work.

Your task: [TASK DESCRIPTION]

Setup:
1. Create a git worktree for your work:
   git worktree add /tmp/delegate-[short-task-name] -B delegate/[short-task-name]
   (use -B to reset the branch if it exists from a previous run)
   If the worktree path already exists, remove it first: git worktree remove /tmp/delegate-[short-task-name]
2. Work in /tmp/delegate-[short-task-name] (NOT the main repo)
3. Commit your changes in the worktree

Rules:
- Work in the worktree only — never modify files in the main repo directory
- If you need clarification: ask the team lead via SendMessage — don't guess
- When done: send a summary to the team lead with what changed, decisions made, and the branch name for review
```

**For read-only tasks, spawn a teammate with this prompt:**

```
You are a teammate working on an independent research task. Do NOT write or edit code in the repo.

First: run /catchup to understand the project and current work.

Your task: [TASK DESCRIPTION]

Rules:
- Use /tmp for any scratch files you need
- If you need clarification: ask the team lead via SendMessage — don't guess
- When done: send your findings to the team lead as a clear summary
```

**Spawn configuration:**
- `subagent_type`: `general-purpose` (needs access to read files, run git commands, search, and write code for write tasks)
- Do NOT use `mode: plan` — delegates need Bash access for `git worktree`, `git diff`, `git status`, and web search
- Run delegate in background so Main can continue working

**If spawning fails** (TeamCreate or Task tool returns an error):
```
Failed to spawn delegate: [error].
You can retry with /delegate "[same task]".
```

Do not retry automatically.

### 5. Confirm to user and continue working

After spawning, tell the user:

**For write tasks:**
```
Delegate active for: [task description]

  [delegate name]: working in git worktree on branch delegate/[short-task-name]

Continue your work. The delegate will:
- Ask you if it needs clarification
- Notify you when done with a summary and branch name

To stop: say "stop [delegate name]" anytime.
```

**For read-only tasks:**
```
Delegate active for: [task description]

  [delegate name]: researching in background

Continue your work. The delegate will:
- Ask you if it needs clarification
- Notify you when done with findings

To stop: say "stop [delegate name]" anytime.
```

Then continue your own work as Main. The delegate works independently.

### 6. Handle delegate communication

**When the delegate asks a question:** The delegate messages the team lead (you). Forward the question to the user and relay their answer back to the delegate.

**When the delegate finishes:** The user gets a summary. For write tasks, the summary includes the branch name. The user decides what to do:
- Review and merge the branch
- Ask the delegate to make changes
- Discard the work

### 7. Cleanup

**When the delegate finishes or the user says "stop [delegate name]":**

1. Send the delegate a shutdown request via SendMessage with `type: shutdown_request`
2. For write tasks, remind the user about the worktree:
   ```
   Delegate finished. Branch: delegate/[short-task-name]

   To review: git diff main...delegate/[short-task-name]
   To merge:  git merge delegate/[short-task-name]
   To clean:  git worktree remove /tmp/delegate-[short-task-name] && git branch -d delegate/[short-task-name]
              (use -D instead of -d if the branch wasn't merged)
   ```
3. Delete the team with TeamDelete

---

## Important notes

- **Delegate does the work independently.** You continue your own task.
- **Human sees delegate messages.** Questions and completion notifications appear inline.
- **Human can intervene anytime.** Answer questions, give feedback, or stop the delegate.
- **Write tasks use git worktree.** Isolated branch, no conflicts with Main's work.
- **Read-only tasks use /tmp.** No repo changes at all.
- **One delegate per `/delegate` call.** Run multiple `/delegate` calls for multiple parallel tasks.
- **Delegate can ask Main for clarification.** It should ask rather than guess on ambiguous requirements.

---

## Examples

### Write task (tests)

```
User: /delegate "write unit tests for the auth module"

Claude: Analyzing task... Writing tests — this is an independent write task, good fit for delegation.

Delegate active for: write unit tests for the auth module

  test-writer: working in git worktree on branch delegate/auth-tests

Continue your work. The delegate will:
- Ask you if it needs clarification
- Notify you when done with a summary and branch name

[User continues working on their own task]
[Delegate finishes and sends summary]

Delegate finished. Branch: delegate/auth-tests

To review: git diff main...delegate/auth-tests
To merge:  git merge delegate/auth-tests
To clean:  git worktree remove /tmp/delegate-auth-tests && git branch -d delegate/auth-tests
```

### Read-only task (research)

```
User: /delegate "research how other CLIs handle plugin systems, summarize findings"

Claude: Analyzing task... Research only — no repo changes needed.

Delegate active for: research how other CLIs handle plugin systems

  researcher: researching in background

Continue your work. The delegate will:
- Ask you if it needs clarification
- Notify you when done with findings

[User continues working]
[Delegate sends research summary]
```

### Read-only task (non-development)

```
User: /delegate "analyze Milan's last 10 matches and summarize their performance"

Claude: Analyzing task... Research only — no repo changes needed.

Delegate active for: analyze Milan's last 10 matches

  sports-analyst: researching in background

Continue your work. The delegate will:
- Ask you if it needs clarification
- Notify you when done with findings

[User continues working]
[Delegate sends analysis summary with match results, stats, and performance trends]
```

### Task better suited for /with-advisor

```
User: /delegate "help me design the API endpoints"

Claude: This task needs your continuous input. Use /with-advisor instead — it keeps you in the loop with expert feedback.
```


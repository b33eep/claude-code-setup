# With Advisor: Expert Pair Programming

Spawn expert advisor(s) that monitor your work and give proactive domain feedback. You stay in control — advisors supplement your judgment.

## Usage

```
/with-advisor "implement OAuth login with JWT tokens"
/with-advisor "optimize the slow database queries"
/with-advisor "design a plugin system for the CLI"
```

## Tasks

### 1. Validate arguments

The command requires a task description.

**No arguments:**
```
Usage: /with-advisor "task description"

Example: /with-advisor "implement OAuth login with JWT tokens"
```

Stop here. Do not proceed.

### 2. Assess task complexity

If the overhead of spawning advisors exceeds the benefit, refuse:

```
Task is too simple for advisors. Just do it directly.
```

Stop here. Do not proceed. Otherwise, continue.

### 3. Select advisor expertise

Analyze the task and decide which advisor expertise adds value. Think about:
- What domain knowledge would catch mistakes you'd miss?
- What expertise would improve the design, not just the code?

**Rules:**
- Max 2 advisors
- Only spawn a second if genuinely different expertise is needed
- Frame advisors around the **problem** being solved, not the tool being built

Examples:

| Task | Advisors | Why |
|------|----------|-----|
| "implement OAuth login" | Security Expert, Auth Domain Expert | Security-sensitive, unfamiliar domain |
| "optimize database queries" | Performance Expert | Specific domain expertise |
| "refactor the auth module" | Codebase Patterns Expert | Large change, consistency matters |
| "add WebSocket support" | Distributed Systems Expert | Real-time, concurrency concerns |
| "migrate to TypeScript" | TypeScript Migration Expert | Large scope, many gotchas |

### 4. Create team and spawn advisors

Use Agent Teams (TeamCreate + Task tool) to spawn each advisor.

**Team setup:**
- Team name: `advisor-session` (or similar short name)
- Create tasks for tracking
- If a team named `advisor-session` already exists (user ran `/with-advisor` before), ask: "Advisors from a previous session are still active. Replace them with new advisors? [Yes / No]". If Yes, shut down existing advisors first (SendMessage with `type: shutdown_request`), delete the team, then create a new one. If No, stop here.

**For each advisor, spawn a teammate with this prompt:**

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

**Spawn configuration:**
- `subagent_type`: `general-purpose` (needs access to read files, run git commands, search)
- Do NOT use `mode: plan` — advisors need Bash access for `git diff`, `git status`, and web search
- Run advisors in background so Main can continue working

**If spawning fails** (TeamCreate or Task tool returns an error):
```
Failed to spawn advisor: [error]. Continuing without advisors.
You can retry with /with-advisor "[same task]".
```
Continue working on the task without advisors. Do not retry automatically.

### 5. Challenge approach with advisors

**Wait for advisors to finish onboarding** (they send an initial assessment). Then, before writing any code:

1. Formulate your planned approach — how you intend to solve the task (structure, key decisions, sequence)
2. Share it with each advisor via SendMessage:

```
My planned approach for [task]:

[Approach summary — what you'll build, how, key decisions]

Challenge this before I start. What am I missing? What would you do differently?
```

3. **Wait for advisor feedback.** Don't start implementing yet.
4. Incorporate feedback (or decide to proceed anyway — you're in control), then tell the user:

```
Approach discussed with advisors. Key feedback:
- [summary of advisor input]

Starting implementation.
```

**If advisors haven't responded yet** after you've shared your approach (i.e., you've been idle waiting with nothing to do), tell the user and start implementing. Share the approach when they're ready — it becomes a retroactive review of the direction, which is still valuable.

### 6. Implement with advisor collaboration

Now implement. You are Main — you do the work.

Tell the user:
```
You'll see advisor messages inline. Act on them or ignore them — your call.
To stop: say "stop advisors" anytime.
```

**Ask advisors at decision points:** When you hit a fork — multiple valid approaches, unclear tradeoff, unfamiliar territory — ask the advisor BEFORE choosing:

```
Decision point: [describe the choice]
Option A: [approach] — [tradeoff]
Option B: [approach] — [tradeoff]

What's your take?
```

Don't ask for every small choice — not variable naming, file organization, or routine patterns. Ask when the advisor's domain expertise would genuinely help.

After receiving the advisor's recommendation, briefly tell the user what you decided:
```
Going with [choice] based on advisor input: [one-line reason].
```

**Progress updates:** After significant changes (completing a component, committing code), send a brief update:

```
Progress update: [what just changed]
Please review the latest changes via git diff.
```

Don't update after every small edit — only at meaningful checkpoints.

**Stopping advisors:** When the task is complete (or the user says "stop advisors"), send each advisor a shutdown request via SendMessage with `type: shutdown_request`. Then delete the team with TeamDelete.

---

## Important notes

- **You (Main) do the work.** Advisors challenge your thinking and advise — they don't write code.
- **Challenge before coding.** Share your approach with advisors before implementing. Their biggest value is catching bad directions early.
- **Ask during coding.** At decision points where domain expertise helps, ask the advisor before choosing. Don't just push updates after the fact.
- **Human sees everything.** All advisor messages appear in the session.
- **Human can intervene anytime.** They can respond to advisors, ignore them, or stop them.
- **Advisors don't edit code.** They read, research, and send messages. That's it.
- **Max 2 advisors.** One is usually enough. Two only if genuinely different expertise.
- **Mid-session:** If you're already working on a task when the user invokes `/with-advisor`, include a summary of work done so far in the advisor's task description.

---

## Examples

### Standard invocation

```
User: /with-advisor "implement OAuth login with JWT tokens"

Claude: Analyzing task... This involves authentication and security — good fit for advisors.

Advisors active for: implement OAuth login with JWT tokens

  security-advisor: Security Expert — onboarding...
  auth-advisor: Auth Domain Expert — onboarding...

[Advisors onboard and send initial assessments]

Claude → Advisors: "My planned approach: Use passport.js with JWT, store refresh
tokens in httpOnly cookies, access tokens in memory. Challenge this?"

security-advisor: "Cookie storage is good. But add token rotation on refresh —
without it, a leaked refresh token is valid forever."

auth-advisor: "passport.js works, but check if the project already has auth
middleware. Don't introduce a second pattern."

Claude → User: Approach discussed with advisors. Key feedback:
- Add refresh token rotation
- Check for existing auth middleware first

Starting implementation.

[During implementation, Claude hits a decision point]

Claude → security-advisor: "Decision point: HMAC-SHA256 vs RSA for JWT signing.
Single service, no external token consumers. Your take?"

security-advisor: "HMAC-SHA256. RSA only matters when other services need to
verify without the secret. Single service = symmetric is simpler and faster."

Claude → User: Going with HMAC-SHA256 based on advisor input: simpler for single-service, no need for asymmetric keys.

[Claude implements, sends progress updates at checkpoints]
```

### Advisors still onboarding

```
User: /with-advisor "add rate limiting to the API"

Claude: Good fit for advisors — spawning a performance expert.

  perf-advisor: API Performance Expert — onboarding...

[Claude formulates approach, shares it with advisor]
[Advisor hasn't responded yet — still running /catchup]

Claude → User: Advisor is still onboarding. Starting implementation — I'll share
my approach when they're ready so they can review the direction.

[Claude starts implementing]
[Advisor finishes onboarding, receives the approach retroactively]

perf-advisor: "Your approach uses a fixed window counter. Consider sliding
window instead — fixed windows allow burst traffic at window boundaries."

Claude → User: Advisor caught a design issue — fixed window allows bursts at
boundaries. Switching to sliding window before I go further.
```

### Simple task rejected

```
User: /with-advisor "fix typo in README"

Claude: Task is too simple for advisors. Just do it directly.
```


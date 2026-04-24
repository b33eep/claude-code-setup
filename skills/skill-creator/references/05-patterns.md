# Skill Patterns

Five patterns cover most skills. Picking the right one before writing instructions saves rewrites. Most skills fit one pattern cleanly; occasionally a skill blends two.

## Choosing a pattern

Before picking, frame the task two ways — "problem-first" vs. "tool-first":

- **Problem-first:** user describes an outcome ("set up a project workspace"), the skill orchestrates the tools. Patterns 1, 3, 5 fit.
- **Tool-first:** user has a tool (MCP, API, library) and wants expertise on how to use it well. Patterns 2, 4 fit.

Then pick by fit:

| Pattern | Best when | Typical complexity |
|---|---|---|
| 1 — Sequential workflow | Clear multi-step process, one ordering | Low–medium |
| 2 — Multi-MCP coordination | Workflow crosses services | Medium–high |
| 3 — Iterative refinement | Quality improves with repeat passes | Medium |
| 4 — Context-aware tool selection | Same outcome, different tools | Medium |
| 5 — Domain-specific intelligence | Expertise is the point | Medium–high |

## Pattern 1 — Sequential workflow orchestration

**Use when:** the task is multi-step, steps have a fixed order, and each step may depend on the previous.

**Key techniques:**
- Explicit step ordering (Step 1, Step 2, …)
- Named dependencies (Step 3 uses output of Step 1)
- Validation at each stage
- Rollback instructions for failures

**Structure:**

```markdown
# Workflow: Onboard New Customer

## Step 1: Create Account

Call MCP tool: `create_customer`
Parameters: `name`, `email`, `company`
Validate: response contains `customer_id`

## Step 2: Setup Payment

Call MCP tool: `setup_payment_method`
Parameters: `customer_id` (from Step 1)
Wait for: payment method verification

## Step 3: Create Subscription

Call MCP tool: `create_subscription`
Parameters: `plan_id`, `customer_id` (from Step 1)
Validate: `status == "active"`

## Step 4: Send Welcome Email

Call MCP tool: `send_email`
Template: `welcome_email_template`
Parameters: `customer_id`, `plan_name`

## Rollback (if any step fails)

- Step 2 fails → delete customer from Step 1 via `delete_customer(customer_id)`
- Step 3 fails → keep customer, flag for manual subscription creation
- Step 4 fails → non-critical, log and continue
```

**Canonical examples:** customer onboarding, deploy pipelines, release workflows.

## Pattern 2 — Multi-MCP coordination

**Use when:** a workflow needs to pass data across multiple MCP servers (Figma → Drive → Linear → Slack, for instance).

**Key techniques:**
- Clear phase separation (one phase per MCP)
- Explicit data passing between phases
- Validation before transitioning phases
- Centralized error handling

**Structure:**

```markdown
# Workflow: Design-to-development handoff

## Phase 1: Design Export (Figma MCP)

1. Export design assets from Figma
2. Generate design specifications
3. Create asset manifest `{file_url, component_name, version}`

Output: list of asset records passed to Phase 2.

## Phase 2: Asset Storage (Drive MCP)

1. Create project folder in Drive
2. Upload all assets from Phase 1 manifest
3. Generate shareable links
4. Update manifest with Drive links

Output: manifest enriched with `drive_link` per asset.

## Phase 3: Task Creation (Linear MCP)

1. Create development tasks — one per component
2. Attach Drive links from Phase 2
3. Assign to engineering team
4. Set labels: `design-review`, `sprint-current`

Output: list of Linear task IDs.

## Phase 4: Notification (Slack MCP)

1. Post handoff summary to `#engineering`
2. Include:
   - Link to Linear board filtered by the new task IDs
   - Link to Drive folder from Phase 2
   - Figma source link from Phase 1

## Error handling

If any phase fails, stop. Do not proceed to the next phase. Report which phase failed and what the user needs to do to resume (e.g. "Phase 2 failed: Drive quota exceeded. Free up space and ask me to retry.").
```

**Canonical examples:** design-to-dev handoff, incident runbooks that page on-call + create tickets + post status, billing pipelines that update CRM + billing + accounting.

## Pattern 3 — Iterative refinement

**Use when:** the first output is rarely good enough; quality improves through repeat passes with specific checks in between.

**Key techniques:**
- Explicit quality criteria (what does "good" look like?)
- Validation script or checklist between passes
- Known stopping condition
- Don't iterate forever — cap at N passes

**Structure:**

```markdown
# Iterative Report Generation

## Initial Draft

1. Fetch data via MCP (use `references/query.md` for the standard query)
2. Generate first draft report using `assets/report-template.md`
3. Save to `./draft.md`

## Quality Check

Run validation script:

```bash
python scripts/check_report.py ./draft.md
```

Common issues the script flags:
- Missing required sections (executive summary, methodology, findings)
- Inconsistent number formatting
- Broken internal references
- Data points inconsistent with source

## Refinement Loop (max 5 passes)

For each issue the script flagged:
1. Address the specific issue
2. Regenerate only the affected section — do not rewrite the whole report
3. Re-run `scripts/check_report.py`

Stop when:
- Script reports zero issues, OR
- 5 passes completed (at this point, escalate to the user)

## Finalization

1. Apply final formatting: `scripts/format_report.py ./draft.md`
2. Generate executive summary from the body
3. Save final as `./report-{YYYY-MM-DD}.md`
```

**Canonical examples:** report generation, content rewriting, code refactoring in a specific style, image generation with specific constraints.

## Pattern 4 — Context-aware tool selection

**Use when:** the user's goal is the same across contexts, but the right tool changes based on the situation (file type, size, collaboration need, location).

**Key techniques:**
- Clear decision criteria upfront
- Fallback options if the preferred tool fails
- Transparency about the choice to the user

**Structure:**

```markdown
# Smart File Storage

## Decision Tree

1. Check file type and size
2. Determine best storage location:

   | File | Location | MCP |
   |---|---|---|
   | Large files (>10MB) | Cloud storage | `s3` or `gcs` MCP |
   | Collaborative docs | Notion/Google Docs | `notion` or `gdocs` MCP |
   | Code files | GitHub | `github` MCP |
   | Temporary files | Local `./tmp/` | — |

## Execute Storage

Based on the decision:
- Call the appropriate MCP tool
- Apply service-specific metadata (tags, descriptions)
- Generate access link for the user

## Provide Context to User

Always tell the user which storage was picked and why:

> "Stored `report.pdf` in Google Drive (15 MB, exceeds GitHub LFS-free limit) — link: ..."

This transparency lets the user override if they wanted a different location.

## Fallback

If the preferred tool is unavailable:

| Original | Fallback |
|---|---|
| S3 unavailable | Use local `./tmp/` + tell user to upload manually |
| Notion rate-limited | Queue for retry, notify user |
| GitHub auth fails | Save locally, prompt for re-auth |
```

**Canonical examples:** file storage routing, code-search across multiple indexes, issue creation across Linear/GitHub/Jira based on repo.

## Pattern 5 — Domain-specific intelligence

**Use when:** the skill adds specialized expertise beyond what tool access provides. The skill's value is the embedded knowledge, not the tool orchestration.

**Key techniques:**
- Domain expertise encoded in logic, not delegated to Claude's general reasoning
- Comprehensive documentation of the expertise
- Clear governance / audit trail for decisions

**Structure:**

```markdown
# Payment Processing with Compliance

## Before Processing (Compliance Check)

1. Fetch transaction details via MCP
2. Apply compliance rules:
   - Check sanctions lists (OFAC, EU consolidated, UN)
   - Verify jurisdiction allowances per `references/jurisdictions.md`
   - Assess risk level using `scripts/risk_score.py`
3. Document compliance decision in the audit log:

   ```
   {timestamp, transaction_id, checks_performed, result, reasoning}
   ```

## Processing

IF compliance passed:
- Call payment processing MCP tool
- Apply appropriate fraud checks based on risk level:
  - Low risk → standard checks
  - Medium risk → enhanced checks + 2FA
  - High risk → manual review queue

ELSE:
- Flag for manual review — do NOT process automatically
- Create compliance case via MCP
- Notify compliance team

## Audit Trail

Every decision and action is logged:
- All compliance checks (pass/fail + reason)
- Processing decision (or decline reason)
- Fraud check results
- Final disposition (processed, declined, queued)

Generate audit report on demand via `scripts/audit_report.py`.

## Rules (see `references/compliance-rules.md` for full detail)

- Never process without compliance check — no exceptions
- Always log, even for declined transactions
- Escalate ambiguous cases — don't guess
- Sanctions lists refresh daily; check timestamp on each transaction
```

**Canonical examples:** financial compliance, legal contract review, medical triage, safety-critical approvals, security audits.

## Skills that wrap an MCP

A special class of skill: the user already has an MCP server connected (Notion, Linear, Figma), and the skill teaches Claude how to use it well. This doesn't replace patterns 1–5 — it's a framing that usually lands on pattern 1 (sequential) or pattern 5 (domain-specific).

**The split of responsibilities:**

| MCP (Connectivity) | Skill (Knowledge) |
|---|---|
| Connects Claude to the service | Teaches Claude how to use the service effectively |
| Provides real-time data + tool invocation | Captures workflows and best practices |
| Tells Claude **what** it can do | Tells Claude **how** it should do it |

**Why bother?** Without a skill, users connect an MCP and don't know what to do next. Conversations start from scratch. Each user prompts differently; results are inconsistent. The skill closes this gap — a pre-built workflow activates when needed.

**When to write an MCP-wrapping skill:**

- You built (or use) an MCP server with a non-trivial workflow (more than "call one tool, get an answer")
- You find yourself re-explaining the same sequence of MCP calls across sessions
- Support questions follow the pattern "how do I do X with your integration?"

**Structure tips:**

- Identify the top 2–3 workflows users actually want (talk to real users, don't guess)
- For each, map out the MCP tool sequence with parameters and dependencies
- Embed the best-practice guidance in SKILL.md — error handling, validation, idempotency
- Store longer tool-reference material in `references/tool-reference.md` rather than SKILL.md

**Typical pattern fit:** patterns 1 (sequential workflow), 2 (multi-MCP if the workflow spans services), or 5 (domain-specific if the skill adds expertise beyond raw tool access).

## Blending patterns

Skills sometimes combine patterns. Common combinations:

- **1 + 5:** Sequential workflow with domain rules at each step (e.g. customer onboarding with fraud checks)
- **2 + 4:** Multi-MCP where each phase's tool depends on context (e.g. incident response routes by severity)
- **3 + 5:** Iterative refinement against domain-specific quality criteria (e.g. legal document drafting)

If you find yourself blending, **pick the dominant pattern** and structure around it. Add the secondary pattern as a sub-section rather than parallel structure — Claude navigates linearly better than it navigates matrices.

## When the skill doesn't fit any pattern

Two possibilities:

1. **The task is too small.** If the skill is one step, maybe it doesn't need to be a skill — a direct MCP call or prompt template might suffice.
2. **The task is multi-skill.** If the "skill" really describes two workflows, split into two skills. One skill per bounded task.

Either way: if no pattern fits, that's signal worth paying attention to.

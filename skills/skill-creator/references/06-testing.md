# Testing Skills

A skill that looks good in review can still fail in real use. Testing catches three distinct classes of problems: the skill doesn't load, the skill loads but does the wrong thing, or the skill does the right thing but costs more than it saves.

## Three test dimensions

Run all three before shipping. Each catches different bugs.

### 1. Triggering tests

**Question:** Does Claude load the skill when it should, and NOT load it when it shouldn't?

**Method:** In a fresh Claude conversation (no prior context), ask questions and observe whether the skill is picked.

**Test suite structure:**

```markdown
## Should trigger

- "Help me set up a new ProjectHub workspace"
- "I need to create a project in ProjectHub"
- "Initialize a ProjectHub project for Q4 planning"
- "Can you organize my team's tasks by sprint?"   (paraphrased)
- "Start a new workspace for the marketing launch"  (no product name mentioned)

## Should NOT trigger

- "What's the weather in San Francisco?"                     (unrelated)
- "Help me write Python code"                                (coding, not PM)
- "Create a spreadsheet"                                     (different tool)
- "Tell me about ProjectHub"                                 (informational, not task)
- "Fix this bug in main.py"                                  (coding, touches none of the skill's domain)
```

Target:

- **Triggers on 4+ out of 5 "should trigger"** — especially the paraphrased ones
- **Zero triggers on "should NOT trigger"** — false positives are usually more expensive than false negatives

If triggering is wrong, the **description is the first suspect**. Rewrite per `03-writing-descriptions.md`.

### 2. Functional tests

**Question:** Does the skill produce the correct output?

**Method:** For each use case, run the skill end-to-end and check the result against expected output.

**Test case template:**

```markdown
## Test: Create project with 5 tasks

Given:
- Project name: "Q4 Planning"
- 5 task descriptions: [...]

When:
- Skill executes the workflow

Then:
- Project created in ProjectHub with name "Q4 Planning"
- 5 tasks created, each linked to the project
- Tasks have correct properties (title, description, assignee)
- No API errors
- User receives confirmation message with project link
```

Run 2–5 of these per use case from Step 1 of skill creation. Also add:

- **Edge cases:** empty inputs, max-length inputs, inputs with unusual characters
- **Error paths:** what happens when the MCP is down, when authentication fails, when validation rejects input

Functional failures point to **SKILL.md instructions** — they're ambiguous, missing, or wrong. Rewrite per `04-writing-instructions.md`.

### 3. Performance comparison

**Question:** Does the skill save tokens and tool calls vs. doing the task without it?

**Method:** Run the same task twice — once with the skill enabled, once disabled. Count:

- Messages exchanged
- Tool calls executed
- Total tokens consumed
- Time to completion
- User corrections / redirects needed

**Baseline comparison table:**

| Metric | Without skill | With skill | Delta |
|---|---|---|---|
| Messages | 15 | 3 | −80% |
| Tool calls | 22 | 11 | −50% |
| Failed API calls | 3 (retry loops) | 0 | −100% |
| Tokens | 12,000 | 6,000 | −50% |
| User corrections | 4 | 0 | −100% |
| Time | 3:40 | 1:15 | −65% |

If the skill doesn't improve the numbers, something's wrong. Common causes:

- SKILL.md is too long — loads too much context for the task
- Skill requires many clarifying questions — description wasn't precise enough about expected inputs
- Skill's instructions aren't confidence-inspiring enough — Claude asks the user instead of acting

Performance failures often mean **the skill's scope is wrong** — too broad, too narrow, or in the wrong place.

## Iteration loop

Testing isn't one-and-done. Skills are living artifacts.

1. **Test** the 3 dimensions above
2. **Note failures** — with specifics (which query, what went wrong, expected vs. actual)
3. **Fix the corresponding artifact** (description for triggering, instructions for functional, scope for performance)
4. **Re-test** the failing case plus the full suite (fixes sometimes regress other tests)
5. **Repeat** until the suite is green

Most skills need 2–4 iterations to settle.

## Monitoring after ship

After shipping a skill, watch for two signals:

### Undertriggering signals

- Users manually enable the skill when it should've auto-triggered
- Users ask, "how do I get the X skill to load?"
- The skill's trigger rate in analytics is low
- Users do the task manually even when the skill would help

**Fix:** add detail, trigger phrases, and technical keywords to the description.

### Overtriggering signals

- Users disable the skill
- Users complain the skill loads when they don't want it
- The skill's trigger rate is high but its usage rate is low (loaded, then ignored)
- Users work around the skill to get to the general-purpose behavior

**Fix:** add negative triggers, narrow the description scope, split into two more-specific skills if scope is genuinely different.

## Scripted testing

For skills used repeatedly or in production, automate the triggering and functional tests:

```bash
# Example — run N triggering tests
for query in "${should_trigger[@]}"; do
  result=$(claude --one-shot "$query" | grep -c "skill loaded: my-skill")
  [ "$result" -eq 1 ] || echo "FAIL: $query"
done
```

Manual testing is fine for small personal skills; automated testing is a must for skills shared across a team. Keep the test suite in the skill's own repo alongside the code.

## When Anthropic's skill-creator disagrees with your own testing

The skill-creator can suggest improvements and flag issues, but **it does not run automated tests**. Trust your concrete test runs over abstract feedback. Use the skill-creator for design review; use real conversations for correctness.

## Testing checklist

- [ ] Triggering — 5+ should-trigger queries, 5+ should-NOT-trigger queries, ≥80% hit rate on triggers, 0% false positives
- [ ] Functional — at least 1 test per use case from creation Step 1, covers happy path + 1 error path
- [ ] Performance — baseline comparison shows net win in 2+ metrics
- [ ] Post-ship — monitored for 1+ week before declaring stable

# Frontmatter Reference

The YAML block at the top of `SKILL.md` is the single most important part of a skill. Claude reads it on every request to decide whether the skill is relevant. Get this wrong and the skill never loads.

## Minimal required format

```yaml
---
name: skill-name
description: What it does. Use when the user asks to [specific phrases].
type: command
---
```

That's the minimum. Everything else is optional.

## Required fields

### `name`

- **kebab-case only.** `customer-onboarding` ✓, `CustomerOnboarding` ✗, `customer_onboarding` ✗, `Customer Onboarding` ✗
- Must exactly match the **folder name**
- No `claude` or `anthropic` prefix — reserved by Anthropic

| Wrong | Why | Correct |
|---|---|---|
| `My Cool Skill` | spaces + capitals | `my-cool-skill` |
| `notion_project_setup` | underscores | `notion-project-setup` |
| `NotionProjectSetup` | camelCase | `notion-project-setup` |
| `claude-helper` | reserved prefix | `assistant-helper` |

### `description`

- **Under 1024 characters**
- **Must include both** what the skill does AND when to use it
- **No XML angle brackets** (`<` or `>`) — security restriction to prevent prompt injection
- No `SKILL.md` body content here — this is the matcher, not the docs

Structure:

> **[What it does]** + **[When to use it with trigger phrases]** + *(optional)* **[Key capabilities]**

Full writing guide with examples: `03-writing-descriptions.md`.

## Optional fields

### `license`

```yaml
license: MIT
```

Add if the skill is open-source. Common values: `MIT`, `Apache-2.0`, `GPL-3.0`.

### `compatibility`

```yaml
compatibility: Requires Node.js 20+; macOS or Linux only.
```

1–500 characters. Describes environment requirements: OS, runtime versions, required system packages, network needs.

### `allowed-tools`

```yaml
allowed-tools: "Bash(python:*) Bash(npm:*) WebFetch"
```

Restricts the tools Claude can call while the skill is active. Format is the same as `.claude/settings.json` permission patterns.

### `metadata`

Arbitrary custom key-value pairs. Common keys:

```yaml
metadata:
  author: Your Name
  version: 1.0.0
  mcp-server: projecthub
  category: productivity
  tags: [project-management, automation]
  documentation: https://example.com/docs
  support: support@example.com
```

Anthropic uses `version` to track updates; author/support for attribution and routing; tags for discovery.

### `source`

```yaml
source: https://github.com/user/repo
```

Free-text pointer to the skill's origin. Useful when skills are ported from other repos.

## Harness-specific fields (claude-code-setup)

These fields are **not part of the upstream Anthropic spec**. They are recognised only by the `claude-code-setup` harness — Claude.ai uploads and direct API use will ignore (or reject) them. If you're shipping a skill outside this repo, remove these before distribution.

### `type`

```yaml
type: command   # or: context
```

- `command` — skill is invoked explicitly via `/skill-name`
- `context` — skill is auto-loaded by the harness when the project's Tech Stack or a file extension matches

### `applies_to` (context skills only)

```yaml
applies_to: [python, fastapi, django]
```

A list of Tech Stack tokens that trigger auto-load. The harness (per `templates/base/global-CLAUDE.md` and [Record 010](../../../docs/records/010-improved-skill-autoloading.md)) matches by checking whether any project Tech Stack item appears in the skill's `applies_to` list. Matching is done at runtime by Claude reading the instructions; de facto case-insensitive string containment.

Common values:

| Category | Values |
|---|---|
| Languages | `python`, `typescript`, `javascript`, `rust`, `go`, `java`, `kotlin`, `ruby`, `php`, `csharp`, `swift` |
| Frameworks | `fastapi`, `django`, `flask`, `react`, `nextjs`, `vue`, `svelte`, `express`, `rails`, `spring` |
| Tools | `docker`, `kubernetes`, `terraform`, `ansible`, `aws`, `gcp`, `azure` |
| Build | `gradle`, `maven`, `cargo`, `npm`, `pnpm`, `make`, `bazel` |

### `file_extensions` (context skills only)

```yaml
file_extensions: [".py", ".pyi"]
```

Extensions that trigger the skill even when the Tech Stack doesn't include the language. Useful when a user edits a single file whose language isn't on the project's main stack.

## Full example

```yaml
---
name: customer-onboarding
description: End-to-end customer onboarding for PayFlow. Handles account creation, payment setup, and subscription activation. Use when the user says "onboard new customer", "set up subscription", or "create PayFlow account".
type: command
license: MIT
compatibility: Requires the `payflow` MCP server to be connected.
allowed-tools: "WebFetch"
metadata:
  author: PayFlow Engineering
  version: 1.2.0
  mcp-server: payflow
  tags: [billing, onboarding, saas]
  documentation: https://docs.payflow.example.com/skills/onboarding
---
```

## Security restrictions

Forbidden in frontmatter (parser will reject):

- **XML angle brackets** (`<` and `>`) anywhere in any field — security against prompt injection, since frontmatter appears in Claude's system prompt
- **Reserved name prefixes** — `claude-*` and `anthropic-*`
- **Code execution in YAML** — only safe YAML is parsed (no Python-style `!!python/object` directives)

Allowed:

- Standard YAML types — strings, numbers, booleans, lists, objects
- Custom metadata fields under the `metadata:` key
- Unicode in description (quote the string if using emoji or special chars)
- Long descriptions up to 1024 characters

## Common mistakes

### Missing delimiters

```yaml
# Wrong
name: my-skill
description: Does things

# Correct
---
name: my-skill
description: Does things
---
```

### Unclosed quotes

```yaml
# Wrong
name: my-skill
description: "Does things

# Correct — either omit quotes or close them
description: "Does things properly"
```

### Description too vague

See `03-writing-descriptions.md` for good/bad examples.

### XML brackets sneaking in

```yaml
# Wrong — < and > break parsing
description: Generates a <report> for the user

# Correct — use words or escape
description: Generates a report document for the user
```

### Context skill without `applies_to`

```yaml
# Wrong — context skill with no way to trigger
type: context

# Correct
type: context
applies_to: [python]
file_extensions: [".py"]
```

## Field naming quick reference

| Field | Required | Scope | For |
|---|---|---|---|
| `name` | yes | Anthropic spec | All skills |
| `description` | yes | Anthropic spec | All skills |
| `license` | no | Anthropic spec | Open-source skills |
| `compatibility` | no | Anthropic spec | Environment notes |
| `allowed-tools` | no | Anthropic spec | Sandboxed skills |
| `metadata` | no | Anthropic spec | Custom author/version/tags |
| `source` | no | Convention | Attribution |
| `type` | yes in harness | **claude-code-setup only** | Invocation style (`command`/`context`) |
| `applies_to` | when `type: context` | **claude-code-setup only** | Tech Stack match |
| `file_extensions` | no | **claude-code-setup only** | File-extension trigger |

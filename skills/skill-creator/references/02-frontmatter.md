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

### `type`

One of:

- `command` — invoked explicitly via `/skill-name`
- `context` — auto-loads when Tech Stack matches

## Optional fields

### For context skills only

```yaml
applies_to: [python, fastapi, django]
file_extensions: [".py", ".pyi"]
```

- `applies_to` — list of Tech Stack tokens that trigger auto-load. Match is case-insensitive substring.
- `file_extensions` — extensions that trigger the skill even when Tech Stack doesn't include the language. Useful for task-based loading.

Common `applies_to` values:

| Category | Values |
|---|---|
| Languages | `python`, `typescript`, `javascript`, `rust`, `go`, `java`, `kotlin`, `ruby`, `php`, `csharp`, `swift` |
| Frameworks | `fastapi`, `django`, `flask`, `react`, `nextjs`, `vue`, `svelte`, `express`, `rails`, `spring` |
| Tools | `docker`, `kubernetes`, `terraform`, `ansible`, `aws`, `gcp`, `azure` |
| Build | `gradle`, `maven`, `cargo`, `npm`, `pnpm`, `make`, `bazel` |

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

| Field | Required | For |
|---|---|---|
| `name` | yes | All skills |
| `description` | yes | All skills |
| `type` | yes | All skills |
| `applies_to` | when `type: context` | Context skills |
| `file_extensions` | no | Context skills — file-triggered loading |
| `license` | no | Open-source skills |
| `compatibility` | no | Environment notes |
| `allowed-tools` | no | Sandboxed skills |
| `metadata` | no | Custom author/version/tags |
| `source` | no | Attribution |

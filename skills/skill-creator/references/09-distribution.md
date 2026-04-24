# Distribution

Skills are an **open standard**. Once a skill folder exists, it can ship anywhere — Claude.ai, Claude Code, the Messages API, the Agent SDK. This reference covers all four paths.

## Where skills can run

| Surface | How skills load | Best for |
|---|---|---|
| **Claude.ai** | Upload via Settings → Capabilities → Skills | End users interacting with skills directly |
| **Claude Code** | Drop in `~/.claude/skills/` or `~/.claude/custom/skills/` | Developers, power users, manual iteration |
| **Messages API** | `container.skills` parameter on requests | Production deployments, agents, pipelines |
| **Agent SDK** | Same folder structure; SDK loads them | Custom agents, internal automation |

The *same folder* works across all surfaces. Authors can note platform-specific expectations via the `compatibility` field.

## Claude.ai upload

1. Compress the skill folder: `zip -r my-skill.zip my-skill/`
2. Claude.ai → Settings → Capabilities → Skills → **Upload skill**
3. Select the `.zip` file
4. Toggle the skill on
5. Test in a new conversation: ask the question from your use case and verify the skill loads

**Prerequisites:**
- Skill folder must contain `SKILL.md` at its root (not nested)
- Frontmatter must be valid (no XML brackets, no reserved names)
- No README.md inside the skill folder (repo-level README is fine)

**Organisation-level deploy (enterprise)**:
- Admins can push skills workspace-wide
- Automatic updates to member accounts
- Centralised management via the Console

## Claude Code (local)

Two paths:

**Base installation** — `~/.claude/skills/<name>/`:
- Comes with `claude-code-setup` via `install.sh`
- Overwritten by updates

**Custom skills** — `~/.claude/custom/skills/<name>/`:
- Survives `claude-code-setup` upgrades
- Managed via `./install.sh --refresh-custom` or `/claude-code-setup` → Upgrade custom
- **Recommended location** for skills you author yourself

After dropping files, run:

```bash
./install.sh --refresh-custom
```

or the `/claude-code-setup` flow, to make the harness recognise the new skill.

## Messages API (programmatic)

For apps, agents, and automated workflows:

```python
from anthropic import Anthropic

client = Anthropic()

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=4096,
    container={
        "skills": [
            {"skill_id": "skill_abc123"}  # uploaded via Console or API
        ]
    },
    messages=[
        {"role": "user", "content": "Onboard new customer Alice <alice@example.com>"}
    ],
)
```

**Key capabilities:**
- `/v1/skills` endpoint for listing and managing skills
- Skills integrate with the Claude Agent SDK
- Version control via the Claude Console

**Requirements:**
- Code Execution Tool beta (provides the sandbox skills need to run)
- Skills uploaded to the workspace via the Console or API

**When to use the API vs. Claude.ai/Code:**

| Use case | Best surface |
|---|---|
| End users interacting with skills directly | Claude.ai / Claude Code |
| Manual testing and iteration during development | Claude.ai / Claude Code |
| Individual, ad-hoc workflows | Claude.ai / Claude Code |
| Applications using skills programmatically | API |
| Production deployments at scale | API |
| Automated pipelines and agent systems | API |

## GitHub distribution (open-source)

For skills you want others to install and use:

### Repository layout

```
my-skill-repo/
├── README.md              # human-facing, with screenshots
├── LICENSE                # MIT, Apache-2.0, etc.
├── CHANGELOG.md           # version history
├── my-skill/              # the actual skill folder
│   ├── SKILL.md
│   ├── references/
│   ├── assets/
│   └── scripts/
└── .github/
    └── workflows/
        └── validate.yml   # optional: lint + trigger tests in CI
```

Note: `README.md` at the **repo root** is for human visitors (installation instructions, demo screenshots). **Do not** put a `README.md` inside the skill folder itself — it breaks Claude.ai upload.

### README content for a GitHub-hosted skill

Focus on outcomes, not features:

**Good:**

> "The ProjectHub skill enables teams to set up complete project workspaces in seconds — including pages, databases, and templates — instead of spending 30 minutes on manual setup."

**Bad:**

> "The ProjectHub skill is a folder containing YAML frontmatter and Markdown instructions that calls our MCP server tools."

If the skill wraps an MCP server, highlight the pair:

> "Our MCP server gives Claude access to your Linear projects. Our skill teaches Claude your team's sprint planning workflow. Together, they enable AI-powered project management."

### Installation guide to include in the repo README

```markdown
# Installing the <skill-name> skill

## For Claude.ai

1. Download the latest release or `git clone https://github.com/org/skills`
2. Zip the skill folder: `zip -r my-skill.zip my-skill/`
3. Open Claude.ai → Settings → Capabilities → Skills
4. Click "Upload skill" and select the zip
5. Toggle the skill on

## For Claude Code

1. Clone into your custom skills directory:
   ```bash
   git clone https://github.com/org/skills ~/.claude/custom/skills/my-skill
   ```
2. Refresh the harness:
   ```bash
   ./install.sh --refresh-custom
   ```
3. Test: ask the expected question; verify the skill loads

## Test

Ask Claude: "<a sentence that should trigger the skill>". The skill should load.
```

### Release cadence

Tag with semver when shipping:

```bash
git tag v1.2.0
git push origin v1.2.0
```

- **major** — breaking: trigger phrases changed, required frontmatter fields added, scripts/ API changed
- **minor** — additive: new references/, new asset templates, new optional fields
- **patch** — fixes: typos, wording improvements, bug fixes in scripts

## Cross-platform caveats

If the skill ships with `scripts/`, note the runtime in `compatibility`:

```yaml
compatibility: "Requires Python 3.11+. scripts/ assumes macOS or Linux shell; Windows users should run under WSL."
```

For a pure-markdown skill (no scripts), portability is universal — just Claude.ai, Code, and API.

## Before shipping — quick checks

- [ ] Tested upload to Claude.ai in a fresh account
- [ ] Verified `applies_to` / `file_extensions` are removed or clearly marked if shipping beyond `claude-code-setup` (they're ignored by Anthropic's parser but can confuse downstream tools)
- [ ] Repository has a human-friendly README
- [ ] Tagged release with semver
- [ ] Changelog updated
- [ ] License file present (for OSS)
- [ ] Screenshots or demo video in the README (optional but dramatically improves adoption)

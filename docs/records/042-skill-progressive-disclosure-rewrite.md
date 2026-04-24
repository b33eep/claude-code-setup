# Record 042: Skill Docs Rewrite — Progressive Disclosure

## Status

Implemented (v57, PR #53)

---

## Problem

Two of the base skills in `skills/` had grown stale enough to be misleading:

**`create-slidev-presentation`** (original, pre-v57):
- Referenced sub-files that never existed in the repo (`components-reference.md`, `configuration-reference.md`, `troubleshooting.md`, `example-configurations.md`) — broken cross-refs in shipped content
- Covered Slidev as of ~2024; no mention of Shiki Magic-Move (Keynote-style code morphing), TwoSlash (inline type info), modern Monaco API, or the dual-pane live-demo pattern that coding presentations need
- Offered bullet-list slide templates only; no narrative structure (conference-talk arc, workshop flow, lightning-talk density)
- Hardcoded old package-manager / Node assumptions

**`skill-creator`** (original, pre-v57):
- A 4-step interactive flow focused on collecting examples, then generating a `SKILL.md`
- Missing the half of skill-building that actually controls quality: description writing with trigger phrases, progressive disclosure, testing methodology, pattern selection, troubleshooting
- New skill authors produced skills that didn't trigger reliably, and debugging was manual

Both skills therefore under-served users and misrepresented the state of the art per Anthropic's *Complete Guide to Building Skills for Claude* (Jan 2026, ~33 pages).

## Options Considered

### Option A — Incremental patches

Fix broken refs; add a few missing sections. Keep the original structure.

**Pros:** Low effort. Stable for existing users.
**Cons:** Doesn't solve the root issue. Authors still build skills without the 3-level disclosure model or the pattern/testing knowledge. The slidev skill remains shallow compared to what Slidev v52 offers.

### Option B — Full rewrite around Progressive Disclosure (chosen)

Rewrite both `SKILL.md` files around the three-level loading model. Move depth from `SKILL.md` bodies into dedicated `references/NN-*.md` files. Ship copy-then-modify templates as `assets/`. Keep `SKILL.md` itself lean — decision flow + critical rules + pointers.

**Pros:**
- Follows Anthropic's spec (Jan 2026 guide) directly
- Bounds SKILL.md size — per upstream soft limit of 5000 words
- Adds first-class coverage of modern features (Slidev v52+ / Skills Spec 2026)
- Makes the skill itself a worked example of progressive disclosure
- Both skills become usable as reference implementations for other skill authors

**Cons:**
- ~5500 new lines across 25 files; large changeset to review
- Users who cached the old skill need to refresh

### Option C — Outsource to Anthropic's own skill-creator

Delete the repo's `skill-creator` and direct users at Anthropic's official tool (referenced in the PDF).

**Pros:** Zero maintenance burden for this repo.
**Cons:** The repo's `skill-creator` is tuned for `claude-code-setup` output conventions (`~/.claude/custom/skills/`, the `type`/`applies_to`/`file_extensions` harness extensions). Delegating means users ship to Claude.ai-native conventions and then have to translate manually.

## Decision

**Option B.** Rewrite both skills around Progressive Disclosure, aligned with the Anthropic Skills Guide (Jan 2026).

Key rules applied to both rewrites:

1. **`SKILL.md` stays lean.** Decision flow + critical rules + resources. Target: under 5000 words. Measured: `create-slidev-presentation` at ~1380, `skill-creator` at ~1150.
2. **Depth in `references/NN-topic.md`.** Each file self-contained so Claude can navigate without re-reading `SKILL.md`.
3. **Templates in `assets/`.** Copy-then-modify starting points.
4. **Generic for OSS.** No teaching-specific, language-specific, or personal content — both skills need to work for any `claude-code-setup` user.
5. **Harness extensions flagged.** `type` / `applies_to` / `file_extensions` are noted as `claude-code-setup`-specific, not Anthropic-spec, so users uploading to Claude.ai understand what to strip.

Same structural pattern applied to both skills:

```
<skill-name>/
├── SKILL.md                  decision flow + rules
├── references/
│   └── NN-topic.md           loaded on demand
└── assets/
    └── *.md                  copy-then-modify
```

## Implementation

See PR #53.

### `create-slidev-presentation`

- Rewritten `SKILL.md` (decision flow, quality checklist reference, anti-patterns, resources)
- 11 reference files:
  - `01-syntax`, `02-layouts`, `03-components`
  - `04-code-presentation` — Shiki + Magic-Move + TwoSlash + Monaco + code groups
  - `05-diagrams-math` — Mermaid + PlantUML + KaTeX
  - `06-themes-styling` — theme gallery + fonts + projector legibility
  - `07-config` — full headmatter schema + `slidev.config.ts` + project structure
  - `08-export-deploy` — PDF/PPTX/PNG + GitHub Pages / Vercel / Netlify + accessibility
  - `09-live-demo-patterns` — dual-pane, demo choreography, audience interaction
  - `10-troubleshooting`
  - `11-quality-checklist` — pre-ship checks
- 5 asset templates:
  - `starter-deck`, `conference-talk-deck`, `workshop-deck`, `lightning-talk-deck`
  - `package-json-template.json`

### `skill-creator`

- Rewritten `SKILL.md` — 8-step interactive flow + critical rules + anti-patterns
- 9 reference files:
  - `01-progressive-disclosure` — 3-level model, references vs. assets vs. scripts
  - `02-frontmatter` — all fields + Anthropic-spec vs. harness-extension separation
  - `03-writing-descriptions` — trigger phrases, good/bad examples
  - `04-writing-instructions` — specificity, structure, when to use scripts
  - `05-patterns` — 5 common patterns + Skills+MCP story
  - `06-testing` — triggering / functional / performance + ≥90% benchmark + iterate-on-single-task
  - `07-troubleshooting` — upload errors, trigger diagnosis, MCP issues
  - `08-checklist` — pre/post-upload
  - `09-distribution` — Claude.ai upload, Messages API, GitHub distribution
- 3 worked-example assets:
  - `skill-template` — minimal SKILL.md scaffold
  - `command-skill-example` — `deploy-staging` (kubectl + docker, rollback, error handling)
  - `context-skill-example` — Python team standards (FastAPI, SQLAlchemy, pytest)

### Documentation

- Website feature pages (`website/pages/features/skills/create-slidev-presentation.mdx`, `skill-creator.mdx`) rewritten to reflect the new structure
- `website/pages/guides/creating-skills.mdx` updated with Progressive Disclosure, `scripts/`, security rules, the 5 patterns, corrected duplicate link

## Validation

- `/do-review` run against each rewrite — 44 findings total, all incorporated
- SKILL.md word counts under 5000 target
- Cross-references verified — every `references/NN-*.md` and `assets/*.md` link resolves
- Grep validation — no `teko`, `kolibee`, `graziano`, `o-tia`, or German content leaks
- CI test suite green after commit `2b4753a` (restored `type: context` literal for `tests/scenarios/10-skill-creator.sh:72`)

## Trade-offs

- **Large PR.** +6,600 / −1,047 lines across 34 files. Reviewed in two `/do-review` passes.
- **Opinionated defaults.** Slidev skill picks Geist as the default font pair; if users hate the choice, alternatives documented in `06-themes-styling.md`.
- **Single version bump.** Both rewrites folded into v57 rather than split across v57/v58. Rationale: the two skills ship together, they share structural conventions, and splitting would double CHANGELOG noise without reducing merge risk.

## References

- Anthropic, *The Complete Guide to Building Skills for Claude* (Jan 2026, ~33 pages): <https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf>
- Slidev documentation: <https://sli.dev>
- Example skills repository: <https://github.com/anthropics/skills>
- Record 007: Coding standards as skills (original skills architecture)
- Record 010: Improved skill auto-loading
- Record 013: Skill creator (original — superseded by this record)

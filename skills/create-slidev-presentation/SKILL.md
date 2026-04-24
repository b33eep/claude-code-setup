---
name: create-slidev-presentation
description: Build or edit Slidev (sli.dev) presentations for tech talks, workshops, conference sessions, and live-coding demos. Use when the user asks to create slides, a deck, a presentation, a workshop deck, a conference talk, or edit an existing slides.md.
type: command
source: https://github.com/b33eep/claude-code-setup
---

# Slidev Presentation Skill

## Overview

Create and edit high-quality Slidev presentations. Slidev turns a single Markdown file into a presentation with live code, animations, diagrams, and PDF/PPTX export. It is the strongest tool available for **tech talks** because slides can show code the way code actually behaves — Monaco editors run inline, Shiki Magic-Move morphs code between states, TwoSlash surfaces TypeScript type info, and the whole deck is a git-versionable markdown file.

**Primary use cases this skill supports:**
- Conference talks (20–40 min, narrative arc, Q&A)
- Workshops and hands-on sessions (live coding, exercises, dual-pane cmd/result)
- Lightning talks (5–10 min, punchy, high animation)
- Live-coding demos embedded in any deck
- Edits to an existing Slidev project

**Runtime requirements:** Node.js ≥ 20.12.0 (Node 24 recommended; Slidev's own `create-slidev` pins `engines.node >=20.12.0`). `pnpm` is the preferred package manager (matches Slidev's official docs); `npm` and `yarn` work identically.

**Slidev version this skill targets:** v52+ (Shiki Magic-Move, TwoSlash, MDC syntax, modern Monaco API all available).

## Decision Flow

Follow this order when the user asks to work with slides.

### 1. Is this a new deck or an existing one?

**New deck** → Go to §2 (Pick a template).
**Existing deck** → Read `slides.md` first. Never rewrite; make targeted edits. Jump to §7 (Editing workflow).

### 2. Pick the right starting template

Ask the user (or infer from their phrasing) which of these fits best:

| User signal | Template | When |
|---|---|---|
| "quick slides", "simple deck", "just a few slides" | `assets/starter-deck.md` | Minimal, no opinionated structure |
| "conference talk", "30 minutes", "keynote-ish" | `assets/conference-talk-deck.md` | Narrative: cover → agenda → sections → Q&A |
| "workshop", "hands-on", "tutorial", "live coding heavy" | `assets/workshop-deck.md` | Mixed: explanation + dual-pane demo slots + exercise markers |
| "lightning talk", "5 minute", "quick demo" | `assets/lightning-talk-deck.md` | 8–12 slides, high animation, one core idea |

If none fits cleanly, start from `starter-deck.md` and compose. **Don't invent a new structure** — copy an asset and modify.

### 3. Bootstrap the project

Run the following (adapt cwd):

```bash
# Create project directory and scaffold (interactive prompt accepts defaults)
pnpm create slidev my-deck
cd my-deck
```

Then **replace** the generated `slides.md` with the selected template from `assets/`. Keep the generated `package.json`, `netlify.toml` (if any), and `.gitignore`.

For a manual bootstrap without the interactive prompt, see `references/07-config.md` → "Minimal project scaffold".

### 4. Configure headmatter

Every deck has one YAML block at the top (headmatter) that configures the whole deck. Start with this **opinionated default** and add options as needed:

```yaml
---
theme: seriph
title: Your Talk Title
info: |
  One-line description — shows in browser tab, PDF metadata, presenter mode.
author: Speaker Name
keywords: [tag1, tag2]
colorSchema: auto
transition: slide-left
mdc: true
lineNumbers: false
drawings:
  persist: false
fonts:
  sans: 'Geist'
  serif: 'Geist'
  mono: 'Geist Mono'
  provider: google
  weights: '400,500,600,700'
lang: en
---
```

**When to change what** — see `references/07-config.md` for a complete field reference.

### 5. Write the slide body

Open the chosen asset template and modify it. Key rules:

- **One concept per slide.** If a slide has two headings, split it.
- **6×6 rule.** Max 6 bullets, max 6 words per bullet. Anything more belongs in speaker notes.
- **Progressive disclosure.** Wrap bullet lists in `<v-clicks>` so the speaker reveals one point at a time.
- **Code blocks always get a language** (` ```ts ` not ` ``` `). Otherwise Shiki cannot highlight.
- **Speaker notes go in HTML comments at the end of each slide.** They only appear in presenter mode.

### 6. Choose the right feature for each idea

Use the feature that matches the intent. Don't reach for Monaco when line highlighting is enough.

| Intent | Feature | Doc |
|---|---|---|
| "Explain this code line by line" | Shiki line highlighting: ` ```ts {1\|3-5\|all} ` | `references/04-code-presentation.md` |
| "Show code evolving between versions" | **Shiki Magic-Move** — morphs between code states | `references/04-code-presentation.md` |
| "Let the audience run the code" | Monaco editor: ` ```ts {monaco-run} ` | `references/04-code-presentation.md` |
| "Show TypeScript type info inline" | **TwoSlash** — type hover & errors rendered static | `references/04-code-presentation.md` |
| "Reveal bullets one by one" | `<v-clicks>` wrapper | `references/03-components.md` |
| "Animate an element sliding in" | `v-motion` directive | `references/03-components.md` |
| "Flow diagram / sequence / architecture" | Mermaid fenced block | `references/05-diagrams-math.md` |
| "Math formula" | KaTeX: `$ E = mc^2 $` inline, `$$...$$` block | `references/05-diagrams-math.md` |
| "Split slide: cmd left, result right" | `layout: two-cols` (or a custom `dual-pane` layout) | `references/09-live-demo-patterns.md` |

### 7. Editing an existing deck

1. **Read `slides.md` in full** before any edit. Understand the headmatter, the slide count, the layouts used, the theme.
2. **Locate the target slide** by heading or content.
3. **Make the smallest possible edit** — add a slide with `---`, change a layout line, add a `<v-clicks>` wrapper. Never reformat unrelated slides.
4. If the change affects the whole deck (e.g. theme change), update only the headmatter.
5. Run `pnpm dev --open` in the deck directory; the user verifies in the browser.

### 8. Export or deploy

Ask the user what they need:

- **PDF** (most common for hand-outs): `pnpm export` — requires `playwright-chromium` as dev dep.
- **Static site**: `pnpm build` produces `dist/`.
- **GitHub Pages / Vercel / Netlify**: see `references/08-export-deploy.md` for ready CI snippets.

## Quality Checklist (before reporting a deck done)

Run through this list before telling the user the deck is ready:

- [ ] Every code block has a language tag
- [ ] No slide exceeds 6 bullets / 6 words per bullet (or speaker note explains why)
- [ ] Lists with 3+ items use `<v-clicks>`
- [ ] Headmatter has `title`, `author`, `theme`, `fonts`, `lang`
- [ ] Speaker notes exist for every content slide (HTML comment at slide end)
- [ ] Section dividers (`layout: section`) break the deck into chapters
- [ ] Final slide uses `layout: end` with a clear takeaway or Q&A cue
- [ ] `pnpm dev` runs without console errors
- [ ] If Monaco is used: `monaco: dev` or `monaco: true` in headmatter
- [ ] If PDF export is promised: `playwright-chromium` installed; `pnpm export` tested

## Anti-Patterns (do not do)

- **Do not paste novels.** If a slide body is longer than ~80 words, split the slide.
- **Do not generate lorem-ipsum content.** Ask the user for real content, or leave `TODO:` markers.
- **Do not use untyped code blocks.** ` ``` code ``` ` → always specify the language.
- **Do not add a README.md inside the skill folder.** (Anthropic skill convention.) Repo-level READMEs are fine.
- **Do not inline an entire reference into SKILL.md.** If you're tempted, you're in the wrong layer — move it to `references/`.
- **Do not recommend themes not in the Slidev theme gallery** unless the user asked for a custom theme.

## Resources

When details are needed beyond this file, **read the specific reference**, don't guess. Each `references/` file is self-contained.

**Internal (bundled, read on demand):**
- `references/01-syntax.md` — markdown conventions, headmatter, slide separators, notes, imports
- `references/02-layouts.md` — all built-in layouts with side-by-side comparison
- `references/03-components.md` — v-click, v-motion, Toc, Link, icons, Youtube, Tweet
- `references/04-code-presentation.md` — Shiki, Magic-Move, TwoSlash, Monaco, code groups
- `references/05-diagrams-math.md` — Mermaid, PlantUML, KaTeX, chemistry
- `references/06-themes-styling.md` — theme gallery, colorSchema, fonts, UnoCSS, scoped CSS
- `references/07-config.md` — complete headmatter schema + `slidev.config.ts`
- `references/08-export-deploy.md` — PDF, PPTX, static, GitHub Pages, Vercel, Netlify, CI
- `references/09-live-demo-patterns.md` — dual-pane layouts, demo choreography, fallback slides
- `references/10-troubleshooting.md` — cache, Monaco, Playwright export, common errors

**Asset templates (bundled, copy-then-modify):**
- `assets/starter-deck.md` — minimal deck
- `assets/conference-talk-deck.md` — 20–40 min narrative structure
- `assets/workshop-deck.md` — hands-on, dual-pane demo slots
- `assets/lightning-talk-deck.md` — 5–10 min, punchy
- `assets/package-json-template.json` — reproducible Slidev + Playwright pinning

**Official:**
- Website: <https://sli.dev>
- Syntax guide: <https://sli.dev/guide/syntax>
- Theme gallery: <https://sli.dev/resources/theme-gallery>
- Addon gallery: <https://sli.dev/resources/addons>
- GitHub: <https://github.com/slidevjs/slidev>

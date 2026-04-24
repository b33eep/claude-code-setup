# Slidev Syntax Reference

## Slide Separator

Slides are separated by `---` surrounded by blank lines:

```markdown
# Slide 1

Content

---

# Slide 2

More content
```

**Critical:** the separator must be on its own line, with a blank line above and below. A `---` directly under a heading will be parsed as a YAML frontmatter opener, not a separator.

## Headmatter vs. Per-Slide Frontmatter

The **first** YAML block in `slides.md` is the headmatter — it configures the whole deck. Every subsequent YAML block is per-slide frontmatter.

```markdown
---
# Headmatter — deck-wide
theme: seriph
title: My Talk
---

# First Slide

Default layout, no per-slide config.

---
# Per-slide frontmatter — applies to THIS slide only
layout: center
background: /hero.jpg
class: text-white
---

# Hero Slide
```

Per-slide fields override headmatter (e.g. `transition`). See `07-config.md` for the full field list.

## Speaker Notes

Any HTML comment block at the end of a slide becomes presenter notes:

```markdown
# Demo Slide

Run the demo here.

<!--
Speaker script:
- Explain why we need composition
- Pause for questions before next slide
- Fallback: show recorded GIF if live demo breaks
-->
```

Notes render markdown and basic HTML inside the presenter view. They never appear in the audience view or in the PDF export (unless `--with-notes` is passed).

## Importing External Slides

Split long decks across files by using `src:`:

```markdown
# Main slides.md

---
src: ./pages/intro.md
---

---
src: ./pages/demo.md
---

---
src: ./pages/qa.md
---
```

Each imported file is a standalone markdown with its own slides (still separated by `---`). The imported file's first frontmatter becomes the first slide's frontmatter (no headmatter).

**When to split:**
- Deck >80 slides: split by section
- Reusing slides across talks: each section lives in its own file
- Multiple authors: one file per author

## Code Blocks

Always specify the language:

````markdown
```ts
const greet = (name: string) => `Hello, ${name}`
```
````

Languages Slidev highlights via Shiki: `ts`, `js`, `tsx`, `jsx`, `py`, `go`, `rs`, `java`, `kotlin`, `swift`, `rb`, `php`, `cs`, `cpp`, `c`, `sh`, `bash`, `zsh`, `yaml`, `json`, `toml`, `sql`, `html`, `css`, `vue`, `svelte`, `md`, `mdx`, and ~200 more. See `04-code-presentation.md` for advanced features (line highlighting, Magic Move, Monaco, TwoSlash).

## Line Highlighting

Append `{...}` after the language to highlight lines, stepped by click:

````markdown
```ts {1|3-5|all}
const user = 'Alice'

function greet(name: string) {
  return `Hi ${name}`
}
```
````

Click 1 → highlight line 1. Click 2 → lines 3–5. Click 3 → all. `|` separates click steps.

Modifiers:
- `{1,3-5}` — highlight specific lines at once (no stepping)
- `{*}` — highlight all
- `{hide|*}` — first click hides everything, second reveals all
- `{at:2}` — start the sequence at click 2
- `{lines:false}` — disable line numbers for this block
- `{maxHeight:'200px'}` — cap height, scroll

## MDC Syntax

When `mdc: true` is in the headmatter, you can attach classes, props, and IDs to markdown elements inline:

```markdown
Text with a [highlighted]{.text-red-500} word.

![alt](/img.png){.rounded-lg.shadow}

A [link with props](https://example.com){target="_blank" rel="noopener"}
```

Turn MDC on for any deck that uses UnoCSS utility classes on markdown elements.

## Scoped CSS

Per-slide CSS via `<style scoped>` inside the slide body:

```markdown
# Slide with custom styles

Some content.

<style scoped>
h1 {
  background: linear-gradient(45deg, #4ec5d4, #146b8c);
  -webkit-background-clip: text;
  color: transparent;
}
</style>
```

Scoped CSS only affects the slide it lives on. For deck-wide CSS, put it in `styles/index.ts` (see `06-themes-styling.md`).

## Inline HTML

Any HTML works inside markdown. Use when markdown can't express something:

```markdown
# Layout tricks

<div class="grid grid-cols-3 gap-4 mt-8">
  <div class="p-4 bg-blue-500/20 rounded">A</div>
  <div class="p-4 bg-green-500/20 rounded">B</div>
  <div class="p-4 bg-amber-500/20 rounded">C</div>
</div>
```

## Vue Components

Built-in and theme components are usable as HTML tags. See `03-components.md` for the full list.

```markdown
<Youtube id="dQw4w9WgXcQ" />
<Tweet id="20" />
<Link to="5">Jump to slide 5</Link>
```

Custom components go in `components/` and are auto-imported.

## Code Snippet Import

Import source files directly to keep code in one place:

````markdown
<<< @/snippets/demo.ts ts {2-4|all}
````

- `@/` resolves to the project root
- Language after the path
- Line-highlight syntax still works

## Per-Slide Classes

```markdown
---
class: text-center text-white bg-sky-900
---

# A centered white heading on a dark background
```

Classes apply to the slide's root element. Use with UnoCSS for quick styling.

## Hiding a Slide

```markdown
---
hide: true
---

# Skipped slide

Present in the file, not shown in the deck.
```

Useful for draft slides you're not ready to show.

## Routing Aliases

```markdown
---
routeAlias: solutions
---

# Solutions
```

Navigate to this slide via `<Link to="solutions">See solutions</Link>`.

## Block Sequencing (`clicks:` and `<v-click at="n">`)

Fine-grained control when a slide has many animated elements:

```markdown
# Clicks

<div v-click="1">First</div>
<div v-click="2">Second</div>
<div v-click="4">Fourth (skips 3)</div>

<div v-click.hide="3">Visible until click 3</div>
```

Override total click count:

```markdown
---
clicks: 10
---

# This slide consumes 10 clicks even if only 2 are used
```

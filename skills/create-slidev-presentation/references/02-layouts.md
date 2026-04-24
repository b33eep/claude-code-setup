# Layouts Reference

## Selection Matrix

Pick the layout that matches the slide's **intent**, not its appearance.

| Intent | Layout | Typical use |
|---|---|---|
| Opening/closing | `cover`, `end` | Title slide, final slide |
| Break the deck into parts | `section` | Chapter divider with big title |
| Regular content | `default` | Bullet points, prose, code |
| Single focused idea | `center` | Short quote, single formula, callout |
| Side-by-side comparison | `two-cols` | Before/after, client/server, option A/B |
| Shared heading over split content | `two-cols-header` | Heading + comparison table |
| Image + commentary | `image-left`, `image-right` | Screenshot + explanation |
| Hero image only | `image` | Full-bleed visual |
| Embed a website | `iframe`, `iframe-left`, `iframe-right` | Live dashboard, docs page, demo app |
| Large number/statistic | `fact` | Key metric, benchmark result |
| Testimonial / citation | `quote` | Customer quote, research finding |
| Standalone message | `statement` | "Everything is broken." |
| Custom design | `none` | Full control, you build the structure |

## All Built-In Layouts

### `cover` — Opening slide

```markdown
---
layout: cover
background: /cover.jpg
class: text-center
---

# Talk Title

## Subtitle

Speaker · Venue · Date
```

Options: `background` (image path or CSS gradient), `class` (text color, alignment).

### `default` — Standard content

```markdown
---
layout: default
---

# Heading

- Point one
- Point two
- Point three
```

No special behavior. Most slides use this implicitly (it's the default when no `layout:` is specified).

### `center` — Centered vertically and horizontally

```markdown
---
layout: center
---

# A single centered idea
```

### `section` — Chapter divider

```markdown
---
layout: section
---

# Part 2: Implementation
```

Typically followed by a `default` slide that details the section.

### `statement` — Bold message

```markdown
---
layout: statement
---

# "Premature optimization is the root of all evil."
```

Larger type than `center`. Use sparingly for emphasis.

### `fact` — Large metric

```markdown
---
layout: fact
---

# 10×

faster builds with `--incremental`
```

The first heading is rendered huge; content below is the caption.

### `quote` — Testimonial

```markdown
---
layout: quote
---

# "Simple things should be simple, complex things should be possible."

Alan Kay
```

### `end` — Closing

```markdown
---
layout: end
---

# Thank You

Questions?

@handle · github.com/user
```

### `two-cols` — Side-by-side

```markdown
---
layout: two-cols
---

# Left column

- Point A
- Point B

::right::

# Right column

- Point C
- Point D
```

The `::right::` marker separates the two slots. Everything above goes left, everything below goes right.

Variants of `two-cols`:

```markdown
---
layout: two-cols
---

::left::
Explicit left slot

::right::
Explicit right slot
```

### `two-cols-header` — Shared top, split bottom

```markdown
---
layout: two-cols-header
---

# Shared heading across both columns

::left::

Left details

::right::

Right details
```

### `image-left` / `image-right` — Image beside content

```markdown
---
layout: image-right
image: /screenshot.png
backgroundSize: contain  # or "cover" (default)
---

# Feature walkthrough

- The image is on the right
- Text on the left
```

Options: `image` (path), `backgroundSize` (`cover` | `contain`), `class`.

### `image` — Full-bleed image

```markdown
---
layout: image
image: /hero.jpg
---

# Overlay text

The text renders on top of the image.
```

### `iframe` / `iframe-left` / `iframe-right` — Embedded URL

```markdown
---
layout: iframe-right
url: https://sli.dev
---

# Live docs

The Slidev documentation loads on the right.
```

Useful for live demos of web apps, dashboards, or docs you want to reference without leaving the deck.

### `none` — Blank canvas

```markdown
---
layout: none
---

<div class="absolute inset-0 flex items-center justify-center">
  <div class="text-9xl font-bold tracking-tighter">
    Custom design
  </div>
</div>
```

No padding, no default styling. You control every pixel. Pair with UnoCSS classes for rapid layout.

## Custom Layouts

Create `layouts/my-layout.vue` and reference it by name:

```vue
<!-- layouts/dual-pane.vue -->
<template>
  <div class="grid grid-cols-2 gap-8 h-full p-12">
    <div class="flex flex-col justify-center">
      <slot name="left" />
    </div>
    <div class="bg-gray-900 rounded-xl p-6 flex flex-col justify-center">
      <slot name="right" />
    </div>
  </div>
</template>
```

Use in slides:

```markdown
---
layout: dual-pane
---

::left::

# Commands

```bash
git init
git add .
git commit -m "initial"
```

::right::

# State

![diagram](/dual-pane-state-1.png)
```

See `09-live-demo-patterns.md` for dual-pane patterns designed for live coding.

## Combining Layouts with `class`

Every layout accepts `class:` in its per-slide frontmatter for quick overrides:

```markdown
---
layout: cover
class: text-left pl-24
---

# Left-aligned cover
```

## Per-Slide Background

Every layout can be given a `background:`:

```markdown
---
layout: default
background: https://cover.sli.dev/nasa-Q1p7bh3SHj8-unsplash.jpg
---

# Text over an image
```

Accepts: image URL, local path, or CSS `linear-gradient()`.

## Layout Class Reference (for CSS overrides)

If you need to style a specific layout globally, add rules in `styles/index.ts`:

```ts
import { defineWindiSetup } from '@slidev/types'

// styles/index.css (imported by default Slidev setup)
```

Each layout renders with a class matching its name:
- `cover` → `.slidev-layout.cover`
- `two-cols` → `.slidev-layout.two-cols`
- etc.

Scope styles tightly to avoid leaking into other layouts.

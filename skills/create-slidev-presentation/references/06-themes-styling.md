# Themes and Styling

## Theme Selection

Slidev ships `default` and `seriph`. The community adds dozens more. Themes ship via npm.

### Recommended themes for tech talks

| Theme | Vibe | Install | Best for |
|---|---|---|---|
| `default` | Clean, minimal | built-in | Starter decks, when you don't care |
| `seriph` | Professional, editorial serif | built-in | Conference keynotes, business audiences |
| `@slidev/theme-apple-basic` | Apple-keynote style | `pnpm add @slidev/theme-apple-basic` | Product launches, polished talks |
| `slidev-theme-penguin` | Modern, colorful | `pnpm add slidev-theme-penguin` | Developer meetups, light tone |
| `slidev-theme-academic` | Academic paper style | `pnpm add slidev-theme-academic` | Research talks, PhD defenses |
| `slidev-theme-geist` | Vercel-inspired | `pnpm add slidev-theme-geist` | Platform/Infra talks, modern dev tools |
| `slidev-theme-dracula` | Dark purple | `pnpm add slidev-theme-dracula` | Night-mode-only talks, dark-loving crowds |
| `slidev-theme-frankfurt` | Bauhaus-ish | `pnpm add slidev-theme-frankfurt` | Design-heavy, strong typography |

Browse the full list: <https://sli.dev/resources/theme-gallery>

### Applying a theme

```yaml
---
theme: seriph
# theme: ./local-theme        # local theme in ./local-theme/
# theme: slidev-theme-geist   # npm theme, auto-installed on first run
---
```

Slidev auto-prompts to install npm themes on first `pnpm dev`.

## Color Scheme

```yaml
colorSchema: auto    # follows system preference (default)
# colorSchema: dark
# colorSchema: light
```

When presenting: the audience usually benefits from **dark** in dim rooms, **light** on projectors with strong ambient light. `auto` is polite; manually force one for known venues.

Override per slide:

```markdown
---
class: dark:invert
---
```

## Fonts

Slidev downloads Google Fonts automatically when `provider: google`. Self-hosted fonts need manual setup.

### Recommended pairs for tech talks

| Sans | Mono | Vibe | Notes |
|---|---|---|---|
| **Geist** | **Geist Mono** | Modern, 2024+ platform-era | Default recommendation. Vercel's fonts, on Google Fonts. |
| Inter | JetBrains Mono | Safe, professional | Battle-tested. Never looks wrong. |
| Space Grotesk | Monaspace Neon | Distinctive, GitHub-flavored | Monaspace must be self-hosted (see below). |
| IBM Plex Sans | IBM Plex Mono | Academic/research, serious | IBM-commissioned, corporate-friendly. |
| Manrope | Fira Code | Friendly, code-with-ligatures | Fira ligatures render nicely in Shiki. |
| DM Sans | DM Mono | Editorial, strong caps | Google Fonts, good for narrative decks. |

### Google Fonts (default)

```yaml
fonts:
  sans: 'Geist'
  serif: 'Geist'
  mono: 'Geist Mono'
  provider: google
  weights: '400,500,600,700'
  italic: false
  local: 'Arial'   # fallback font if Google is unreachable
```

Weights: pick only the ones you need. More weights = larger download.

### Self-hosting (Monaspace, Berkeley Mono, custom)

1. Put font files in `public/fonts/`
2. Create `styles/fonts.css`:

```css
@font-face {
  font-family: 'Monaspace Neon';
  src: url('/fonts/MonaspaceNeon-Regular.woff2') format('woff2');
  font-weight: 400;
  font-display: swap;
}
@font-face {
  font-family: 'Monaspace Neon';
  src: url('/fonts/MonaspaceNeon-Bold.woff2') format('woff2');
  font-weight: 700;
  font-display: swap;
}
```

3. Import in `styles/index.ts`:

```ts
import './fonts.css'
```

4. Reference in headmatter with `provider: none`:

```yaml
fonts:
  sans: 'Inter'
  mono: 'Monaspace Neon'
  provider: none
```

## UnoCSS

Slidev ships [UnoCSS](https://unocss.dev) — atomic CSS utility classes. Use in any markdown, component, or scoped style.

### Commonly useful utilities

```markdown
<div class="grid grid-cols-2 gap-8 mt-8">
  <div class="p-6 bg-blue-500/20 rounded-xl">Left</div>
  <div class="p-6 bg-purple-500/20 rounded-xl">Right</div>
</div>

<div class="absolute bottom-4 right-4 text-sm opacity-50">
  @mentioned
</div>

<div class="text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-sky-400 to-fuchsia-500">
  Hero Text
</div>
```

Common classes:
- **Layout**: `grid`, `grid-cols-{n}`, `flex`, `gap-{n}`, `p-{n}`, `m-{n}`
- **Color**: `text-{color}-{shade}`, `bg-{color}-{shade}/opacity`
- **Type**: `text-{size}`, `font-{weight}`, `tracking-{tight|wide}`
- **Borders**: `rounded`, `rounded-xl`, `border`, `border-{color}`
- **Effects**: `shadow`, `shadow-xl`, `backdrop-blur`, `opacity-{50|75}`
- **Position**: `absolute`, `relative`, `inset-0`, `top-4`, `right-4`
- **Animation**: `animate-pulse`, `animate-bounce`, `transition-all`

### Responsive and state utilities

```markdown
<button class="px-4 py-2 bg-sky-500 hover:bg-sky-600 text-white rounded">
  Click me
</button>
```

## Scoped CSS per Slide

```markdown
# Slide with custom styles

<style scoped>
h1 {
  background: linear-gradient(45deg, #4ec5d4, #146b8c);
  -webkit-background-clip: text;
  color: transparent;
}

ul {
  list-style: none;
  padding: 0;
}

li::before {
  content: '→ ';
  color: #4ec5d4;
}
</style>
```

Scoped styles only affect the slide they live on.

## Global CSS

For deck-wide overrides, create `styles/index.ts`:

```ts
import './custom.css'
```

And `styles/custom.css`:

```css
.slidev-layout h1 {
  letter-spacing: -0.02em;
}

.slidev-layout.cover {
  background: linear-gradient(135deg, #0f172a, #1e293b);
}

code {
  font-feature-settings: 'cv08', 'cv11'; /* Geist Mono stylistic sets */
}
```

## Background Gradients and Effects

### Gradient background

```markdown
---
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
---
```

### Mesh gradient (2024+ aesthetic)

```markdown
---
class: relative overflow-hidden
---

<div class="absolute inset-0 -z-10">
  <div class="absolute top-0 left-0 w-96 h-96 bg-fuchsia-500/30 rounded-full blur-3xl" />
  <div class="absolute bottom-0 right-0 w-96 h-96 bg-sky-500/30 rounded-full blur-3xl" />
</div>

# Hero
```

### Animated background

```markdown
<div class="absolute inset-0 -z-10 opacity-30">
  <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-sky-500 rounded-full blur-3xl animate-pulse" />
</div>
```

## Slide Transitions

Global transition in headmatter:

```yaml
transition: slide-left
```

Options: `slide-left`, `slide-right`, `slide-up`, `slide-down`, `fade`, `fade-out`, `view-transition`.

Override per slide:

```markdown
---
transition: fade
---
```

**Advice:** pick one transition for the whole deck and stick with it. Mixed transitions look amateurish. `slide-left` is a safe default.

## Projector Legibility

Venue projectors vary wildly — some are bright, some wash out, some default to cold color temperatures that shift your palette. Design for the worst case.

### Contrast

- **WCAG AA minimum 4.5:1** for body text against its background. 7:1 (AAA) is safer for back-of-room readability.
- Prefer `slate-950` or `neutral-950` over pure `#000000`. Pure black on projectors produces dead zones where low-contrast detail disappears.
- Prefer `neutral-100` over pure `#ffffff`. Pure white gets washed out in bright rooms.

Check every slide's contrast once at [contrast-ratio.com](https://contrast-ratio.com) or the browser DevTools color picker.

### Font sizes

At the default `canvasWidth: 980`:

- Body text: **minimum 24pt** (Slidev's default `text-base` ≈ 24pt at this width)
- Code blocks: **minimum 20pt** — not tempting to crank smaller to fit more lines
- Headings: at least 48pt

Rule of thumb: if you can read the slide from 3× your monitor's distance, the back of the room can too.

### Color choices

- **Never encode information by color alone.** Color-blind audience members (about 8% of men) will miss it. Pair color with an icon, a label, a position, or a shape.
- Avoid red/green contrasts in diagrams — the most common form of color blindness is red-green. Use blue/orange or blue/yellow instead.
- For Mermaid diagrams, override the default theme: `{theme: 'neutral'}` gives safer defaults than the red-tinted `default`.

### Dark vs. light mode

- **Dim rooms (most conference halls):** dark mode is kinder to eyes and makes code blocks pop. Set `colorSchema: dark`.
- **Bright rooms (lunch sessions, outdoor, large windows):** dark mode washes out on most projectors. Set `colorSchema: light`.
- **Unknown venue:** `colorSchema: auto` is polite but unpredictable. Safer: set explicitly and test in person.

## Custom Theme (Advanced)

To build a full theme:

```
my-theme/
├── package.json          # "name": "slidev-theme-my-theme"
├── layouts/
│   ├── cover.vue
│   ├── default.vue
│   └── end.vue
├── styles/
│   ├── index.ts
│   └── layouts.css
└── components/
    └── MyHeader.vue
```

Publish to npm as `slidev-theme-<name>` and it's auto-discoverable.

Most decks don't need a custom theme — just override `styles/custom.css` in the project.
